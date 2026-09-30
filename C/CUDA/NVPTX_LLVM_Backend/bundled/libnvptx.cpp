//===-- libnvptx.cpp - In-process NVPTX back-end for GPUCompiler ----------===//
//
// Implements the C API in libnvptx.h on top of LLVM's NVPTX back-end: what
// `llc -mtriple=nvptx64-nvidia-cuda -mcpu=... -mattr=+ptx.. -filetype=asm`
// does, without the driver or the file system (the command-line parser is
// only used to set one hidden NVPTX option, see NVPTXCompile).
//
// No `cl::opt` is registered by this file. That keeps the library loadable next
// to another LLVM (Julia's own, or a sibling back-end library) in one process:
// all LLVM symbols are hidden at link time, and the only global state LLVM
// touches is its own private copy.
//
//===----------------------------------------------------------------------===//

#include "libnvptx.h"

#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/Config/llvm-config.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/DiagnosticPrinter.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/CodeGen.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/PrettyStackTrace.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/TargetParser/Triple.h"

#include <clocale>
#include <cstdlib>
#include <cstring>
#include <exception>
#include <mutex>
#include <string>
#include <vector>

using namespace llvm;

namespace {

std::mutex APILock;

void initializeTarget() {
  static std::once_flag Once;
  std::call_once(Once, [] {
    LLVMInitializeNVPTXTargetInfo();
    LLVMInitializeNVPTXTarget();
    LLVMInitializeNVPTXTargetMC();
    LLVMInitializeNVPTXAsmPrinter();
  });
}

Triple targetTriple(bool Is64Bit) {
  return Triple(Is64Bit ? "nvptx64-nvidia-cuda" : "nvptx-nvidia-cuda");
}

const Target &lookupTarget(const Triple &TT) {
  std::string Error;
  const Target *T = TargetRegistry::lookupTarget(TT, Error);
  if (!T)
    report_fatal_error(Twine("NVPTX target not registered: ") + Error);
  return *T;
}

std::unique_ptr<MCSubtargetInfo> createSubtargetInfo(const Triple &TT) {
  return std::unique_ptr<MCSubtargetInfo>(
      lookupTarget(TT).createMCSubtargetInfo(TT, "", ""));
}

// `report_fatal_error` is turned into a C++ exception so the caller gets a
// message instead of an abort. The unwind passes through LLVM frames compiled
// with -fno-exceptions, whose cleanups are skipped, so the LLVM state of the
// failing call must not be destroyed afterwards (see `State` below).
struct FatalError {
  std::string Message;
};
[[noreturn]] void throwingFatalErrorHandler(void *, const char *Reason, bool) {
  throw FatalError{Reason};
}

// Pin the calling thread's C locale to "C" for the duration of a call. The host
// sets the locale from the user's environment (Julia calls setlocale(LC_ALL, "")),
// and with a non-"C" LC_COLLATE msvcrt's strxfrm fails, which libstdc++ 15 turns
// into a std::system_error from std::regex (used by the SPIR-V back-end's
// builtin lookup, see JuliaGPU/GPUCompiler.jl#930). msvcrt's locale is per thread
// once so configured, so this does not touch the host's other threads.
#if defined(_WIN32)
struct ScopedCLocale {
  int PrevConfig;
  std::string Prev;
  ScopedCLocale() : PrevConfig(_configthreadlocale(_ENABLE_PER_THREAD_LOCALE)) {
    if (const char *L = setlocale(LC_ALL, nullptr))
      Prev = L;
    setlocale(LC_ALL, "C");
  }
  ~ScopedCLocale() {
    if (!Prev.empty())
      setlocale(LC_ALL, Prev.c_str());
    if (PrevConfig != -1)
      _configthreadlocale(PrevConfig);
  }
};
#else
struct ScopedCLocale {};
#endif

// Formats diagnostics exactly like llc's LLCDiagnosticHandler and routes them
// to the user's callback, remembering errors for the failure message.
struct CallbackDiagnosticHandler : public DiagnosticHandler {
  NVPTXDiagnosticCallback Callback;
  void *Context;
  std::string Errors;

  CallbackDiagnosticHandler(NVPTXDiagnosticCallback CB, void *Ctx)
      : Callback(CB), Context(Ctx) {}

  void emit(NVPTXDiagnosticSeverity Severity, const std::string &Message) {
    if (Severity == NVPTXDSError)
      Errors += Message + "\n";
    if (Callback)
      Callback(Severity, Message.c_str(), Context);
    else
      errs() << Message << "\n";
  }

  bool handleDiagnostics(const DiagnosticInfo &DI) override {
    if (auto *Remark = dyn_cast<DiagnosticInfoOptimizationBase>(&DI))
      if (!Remark->isEnabled())
        return true;
    std::string Message;
    raw_string_ostream OS(Message);
    if (DI.getKind() == DK_SrcMgr) {
      cast<DiagnosticInfoSrcMgr>(DI).getSMDiag().print(nullptr, OS, false);
      if (!Message.empty() && Message.back() == '\n')
        Message.pop_back();
    } else {
      DiagnosticPrinterRawOStream DP(OS);
      OS << LLVMContext::getDiagnosticMessagePrefix(DI.getSeverity()) << ": ";
      DI.print(DP);
    }
    NVPTXDiagnosticSeverity Severity = NVPTXDSError;
    switch (DI.getSeverity()) {
    case DS_Warning: Severity = NVPTXDSWarning; break;
    case DS_Remark:  Severity = NVPTXDSRemark;  break;
    case DS_Note:    Severity = NVPTXDSNote;    break;
    default: break;
    }
    emit(Severity, Message);
    return true;
  }
};

struct MemoryBufferImpl {
  std::string Data;
};

// Everything LLVM-owned by one compile, in one heap block: deleted on a normal
// return, deliberately leaked after a recovered fatal error.
struct State {
  LLVMContext Context;
  std::unique_ptr<Module> M;
  std::unique_ptr<TargetMachine> TM;
  legacy::PassManager PM;
  SmallVector<char, 0> Output;
};

char *makeMessage(const std::string &S) {
  char *P = static_cast<char *>(std::malloc(S.size() + 1));
  if (P)
    std::memcpy(P, S.c_str(), S.size() + 1);
  return P;
}

// What `llc -mcpu -mattr` does before codegen: functions without explicit
// target attributes get the requested ones.
void setFunctionAttributes(StringRef CPU, StringRef Features, Module &M) {
  for (Function &F : M) {
    AttrBuilder B(M.getContext());
    if (!CPU.empty() && !F.hasFnAttribute("target-cpu"))
      B.addAttribute("target-cpu", CPU);
    if (!Features.empty() && !F.hasFnAttribute("target-features"))
      B.addAttribute("target-features", Features);
    F.addFnAttrs(B);
  }
}

} // namespace

extern "C" {

void NVPTXGetLLVMVersion(unsigned *Major, unsigned *Minor, unsigned *Patch) {
  if (Major) *Major = LLVM_VERSION_MAJOR;
  if (Minor) *Minor = LLVM_VERSION_MINOR;
  if (Patch) *Patch = LLVM_VERSION_PATCH;
}

void NVPTXDisposeMessage(char *Message) { std::free(Message); }

const char *NVPTXGetBufferStart(NVPTXMemoryBufferRef Buffer) {
  return reinterpret_cast<MemoryBufferImpl *>(Buffer)->Data.data();
}
size_t NVPTXGetBufferSize(NVPTXMemoryBufferRef Buffer) {
  return reinterpret_cast<MemoryBufferImpl *>(Buffer)->Data.size();
}
void NVPTXDisposeMemoryBuffer(NVPTXMemoryBufferRef Buffer) {
  delete reinterpret_cast<MemoryBufferImpl *>(Buffer);
}

const char **NVPTXGetProcessors(size_t *Count) {
  std::lock_guard<std::mutex> Guard(APILock);
  initializeTarget();
  // The keys point into the back-end's static tables, so the list is stable.
  static std::vector<const char *> Processors = [] {
    std::vector<const char *> R;
    auto STI = createSubtargetInfo(targetTriple(true));
    for (const SubtargetSubTypeKV &P : STI->getAllProcessorDescriptions())
      R.push_back(P.key());
    return R;
  }();
  if (Count) *Count = Processors.size();
  return Processors.data();
}

const char **NVPTXGetPTXVersions(size_t *Count) {
  std::lock_guard<std::mutex> Guard(APILock);
  initializeTarget();
  static std::vector<const char *> Versions = [] {
    std::vector<const char *> R;
    auto STI = createSubtargetInfo(targetTriple(true));
    for (const SubtargetFeatureKV &F : STI->getAllProcessorFeatures())
      if (StringRef(F.key()).starts_with("ptx"))
        R.push_back(F.key());
    return R;
  }();
  if (Count) *Count = Versions.size();
  return Versions.data();
}

const char *NVPTXGetDataLayout(int Is64Bit) {
  std::lock_guard<std::mutex> Guard(APILock);
  initializeTarget();
  static std::string Layouts[2];
  std::string &DL = Layouts[Is64Bit ? 1 : 0];
  if (DL.empty()) {
    Triple TT = targetTriple(Is64Bit);
    std::unique_ptr<TargetMachine> TM(lookupTarget(TT).createTargetMachine(
        TT, "", "", TargetOptions(), std::nullopt));
    DL = TM->createDataLayout().getStringRepresentation();
  }
  return DL.c_str();
}

int NVPTXCompile(const char *Bitcode, size_t Length,
                 const NVPTXCompileOptions *Options,
                 NVPTXDiagnosticCallback Handler, void *HandlerContext,
                 NVPTXMemoryBufferRef *OutPTX, char **OutMessage) {
  std::lock_guard<std::mutex> Guard(APILock);
  ScopedCLocale Locale;
  initializeTarget();
  if (OutMessage) *OutMessage = nullptr;
  if (OutPTX) *OutPTX = nullptr;

  State *S = nullptr;
  auto fail = [&](const std::string &Message) {
    if (OutMessage) *OutMessage = makeMessage(Message);
    delete S;
    S = nullptr;
    return 1;
  };

  // 1. Validate the options against the back-end's own tables, so a typo is an
  //    error here rather than llc's silent "not a recognized processor" fallback.
  if (!Options || !Options->CPU || !*Options->CPU)
    return fail("no target processor given");
  Triple TT = targetTriple(Options->Is64Bit);
  const Target &TheTarget = lookupTarget(TT);
  {
    auto STI = createSubtargetInfo(TT);
    if (!STI->isCPUStringValid(Options->CPU))
      return fail(std::string("'") + Options->CPU +
                  "' is not a recognized NVPTX processor");
  }
  std::string Features;
  if (Options->PTXMajor != 0 || Options->PTXMinor != 0) {
    std::string PTX = "ptx" + std::to_string(Options->PTXMajor) +
                      std::to_string(Options->PTXMinor);
    auto STI = createSubtargetInfo(TT);
    bool Known = false;
    for (const SubtargetFeatureKV &F : STI->getAllProcessorFeatures())
      Known |= PTX == F.key();
    if (!Known)
      return fail("'" + PTX + "' is not a recognized PTX ISA version");
    Features = "+" + PTX;
  }
  if (Options->OptLevel < 0 || Options->OptLevel > 3)
    return fail("invalid optimization level " +
                std::to_string(Options->OptLevel));
  CodeGenOptLevel OptLevel = static_cast<CodeGenOptLevel>(Options->OptLevel);

  // 2. Compile. `State` is leaked after a fatal error (see above), and the
  //    thread-local pretty-stack list is repaired since its RAII entries
  //    were skipped by the unwind too.
  S = new State;
  const void *PrettyStack = SavePrettyStackState();
  ScopedFatalErrorHandler FatalGuard(throwingFatalErrorHandler);
  try {
    LLVMContext &Context = S->Context;
    auto *DH = new CallbackDiagnosticHandler(Handler, HandlerContext);
    Context.setDiagnosticHandler(std::unique_ptr<DiagnosticHandler>(DH));

    // The IR parser requires a null-terminated buffer: copy.
    SMDiagnostic ParseError;
    auto Buffer = MemoryBuffer::getMemBufferCopy(StringRef(Bitcode, Length),
                                                 "<input>");
    S->M = parseIR(Buffer->getMemBufferRef(), ParseError, Context);
    if (!S->M) {
      std::string Message;
      raw_string_ostream OS(Message);
      ParseError.print(nullptr, OS, false);
      if (!Message.empty() && Message.back() == '\n')
        Message.pop_back();
      return fail(Message);
    }
    Module &M = *S->M;

    // Target machine: typed options instead of llc's command-line flags. The
    // module's triple and datalayout are the target's, whatever it claimed.
    TargetOptions TO;
    TO.MCOptions.AsmVerbose = Options->Verbose != 0;
    // FMAContraction is what `-nvptx-fma-level=1` did: emit `mul.f32`/`add.f32`
    // without the `.rn` rounding modifier so that ptxas may contract them (as
    // nvcc does), while LLVM's own DAG-level fusion stays gated on `contract`
    // fast-math flags. `AllowFPOpFusion::Fast` (llc's `-fp-contract=fast`)
    // would instead fuse every eligible pair in the DAG combiner. The level is
    // a hidden NVPTX `cl::opt` that only counts when it has an occurrence, so
    // set it through the (library-private) command-line parser on every call.
    cl::ResetAllOptionOccurrences();
    if (Options->FMAContraction) {
      const char *const Args[] = {"libnvptx", "-nvptx-fma-level=1"};
      cl::ParseCommandLineOptions(2, Args, "", &nulls());
    }
    S->TM.reset(TheTarget.createTargetMachine(TT, Options->CPU, Features, TO,
                                              std::nullopt, std::nullopt,
                                              OptLevel));
    TargetMachine &TM = *S->TM;
    M.setTargetTriple(TT);
    M.setDataLayout(TM.createDataLayout());
    setFunctionAttributes(Options->CPU, Features, M);

    {
      std::string Message;
      raw_string_ostream OS(Message);
      if (verifyModule(M, &OS)) {
        if (!Message.empty() && Message.back() == '\n')
          Message.pop_back();
        return fail("input module cannot be verified:\n" + Message);
      }
    }

    // Code generation into memory, as llc's legacy pass manager path does.
    legacy::PassManager &PM = S->PM;
    TargetLibraryInfoImpl TLII(TT);
    PM.add(new TargetLibraryInfoWrapperPass(TLII));
    auto *MMIWP = new MachineModuleInfoWrapperPass(&TM);
    bool HasMCErrors = false;
    MMIWP->getMMI().getContext().setDiagnosticHandler(
        [&](const SMDiagnostic &SMD, bool, const SourceMgr &,
            std::vector<const MDNode *> &) {
          DH->emit(NVPTXDSError, "error: " + SMD.getMessage().str());
          HasMCErrors = true;
        });
    raw_svector_ostream OS(S->Output);
    if (TM.addPassesToEmitFile(PM, OS, nullptr, CodeGenFileType::AssemblyFile,
                               /*DisableVerify=*/true, MMIWP))
      return fail("target does not support generation of this file type");
    PM.run(M);
    if (!DH->Errors.empty() || HasMCErrors) {
      std::string Message = DH->Errors;
      if (!Message.empty() && Message.back() == '\n')
        Message.pop_back();
      return fail(Message);
    }

    auto *Out = new MemoryBufferImpl;
    Out->Data.assign(S->Output.begin(), S->Output.end());
    if (OutPTX)
      *OutPTX = reinterpret_cast<NVPTXMemoryBufferRef>(Out);
    else
      delete Out;
    delete S;
    return 0;
  } catch (FatalError &E) {
    RestorePrettyStackState(PrettyStack);
    S = nullptr; // leaked on purpose
    while (!E.Message.empty() && E.Message.back() == '\n')
      E.Message.pop_back();
    return fail("LLVM ERROR: " + E.Message);
  } catch (std::exception &E) {
    // e.g. libstdc++ throwing from std::regex. Never let a C++ exception unwind
    // into the host: on Windows that dies with STATUS_BAD_FUNCTION_TABLE.
    RestorePrettyStackState(PrettyStack);
    S = nullptr; // leaked on purpose
    return fail(std::string("C++ exception: ") + E.what());
  }
}

} // extern "C"
