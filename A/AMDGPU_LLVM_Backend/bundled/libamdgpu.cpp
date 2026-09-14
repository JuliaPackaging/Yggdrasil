//===-- libamdgpu.cpp - In-process AMDGPU back-end for GPUCompiler --------===//
//
// Implements the C API in libamdgpu.h on top of LLVM's AMDGPU back-end and
// lld: what `llc -mtriple=amdgcn-amd-amdhsa -mcpu=... -mattr=...
// --relocation-model=pic -filetype=asm|obj` and `ld.lld -shared` do, without
// the drivers, the command-line parsers, or (for codegen) the file system.
//
// No `cl::opt` is registered by this file. That keeps the library loadable next
// to another LLVM (Julia's own, or a sibling back-end library) in one process:
// all LLVM symbols are hidden at link time, and the only global state LLVM
// touches is its own private copy.
//
//===----------------------------------------------------------------------===//

#include "libamdgpu.h"

#include "lld/Common/CommonLinkerContext.h"
#include "lld/Common/Driver.h"
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
#include "llvm/Support/CrashRecoveryContext.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/FileSystem.h"
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

LLD_HAS_DRIVER(elf)

using namespace llvm;

namespace {

std::mutex APILock;

// lld's fatal errors unwind to its driver through a CrashRecoveryContext,
// which is inert until enabled (lld's own main() enables it too). Enabling it
// would install LLVM's crash signal handlers process-wide, hijacking the
// host's (Julia synchronises its threads with SIGSEGV); the LLVM built into
// this library carries a patch (no-process-wide-handlers.patch) that makes
// that, and the handlers lld's output file would otherwise register, a no-op.
// Recovery from a fatal link error only needs the longjmp in exitLld().
void enableCrashRecovery() { CrashRecoveryContext::Enable(); }

void initializeTarget() {
  static std::once_flag Once;
  std::call_once(Once, [] {
    LLVMInitializeAMDGPUTargetInfo();
    LLVMInitializeAMDGPUTarget();
    LLVMInitializeAMDGPUTargetMC();
    LLVMInitializeAMDGPUAsmPrinter();
    LLVMInitializeAMDGPUAsmParser(); // inline assembly
    enableCrashRecovery();
  });
}

Triple targetTriple() { return Triple("amdgcn-amd-amdhsa"); }

const Target &lookupTarget(const Triple &TT) {
  std::string Error;
  const Target *T = TargetRegistry::lookupTarget(TT, Error);
  if (!T)
    report_fatal_error(Twine("AMDGPU target not registered: ") + Error);
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
  AMDGPUDiagnosticCallback Callback;
  void *Context;
  std::string Errors;

  CallbackDiagnosticHandler(AMDGPUDiagnosticCallback CB, void *Ctx)
      : Callback(CB), Context(Ctx) {}

  void emit(AMDGPUDiagnosticSeverity Severity, const std::string &Message) {
    if (Severity == AMDGPUDSError)
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
    AMDGPUDiagnosticSeverity Severity = AMDGPUDSError;
    switch (DI.getSeverity()) {
    case DS_Warning: Severity = AMDGPUDSWarning; break;
    case DS_Remark:  Severity = AMDGPUDSRemark;  break;
    case DS_Note:    Severity = AMDGPUDSNote;    break;
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

AMDGPUMemoryBufferRef makeBuffer(const char *Data, size_t Length) {
  auto *Out = new MemoryBufferImpl;
  Out->Data.assign(Data, Length);
  return reinterpret_cast<AMDGPUMemoryBufferRef>(Out);
}

// What `llc -mcpu -mattr` does before codegen: functions without explicit
// target attributes get the requested ones. This matters for AMDGPU, whose
// subtarget is looked up per function.
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

// Validates a "+a,-b" feature string against the subtarget's table; returns
// the first unknown name, or empty.
std::string checkFeatures(StringRef Features, const MCSubtargetInfo &STI) {
  SmallVector<StringRef, 8> Names;
  Features.split(Names, ',', -1, /*KeepEmpty=*/false);
  for (StringRef Name : Names) {
    if (Name.empty() || (Name[0] != '+' && Name[0] != '-'))
      return Name.str();
    bool Known = false;
    for (const SubtargetFeatureKV &F : STI.getAllProcessorFeatures())
      Known |= Name.substr(1) == F.key();
    if (!Known)
      return Name.str();
  }
  return std::string();
}

// A temporary file that is removed on scope exit.
struct TemporaryFile {
  SmallString<128> Path;
  bool Valid = false;
  TemporaryFile(StringRef Prefix, StringRef Suffix) {
    int FD;
    if (!sys::fs::createTemporaryFile(Prefix, Suffix, FD, Path)) {
      // The descriptor is an int on every platform, closeFile wants the
      // native handle (a HANDLE on Windows).
      sys::fs::file_t File = sys::fs::convertFDToNativeFile(FD);
      sys::fs::closeFile(File);
      Valid = true;
    }
  }
  ~TemporaryFile() {
    if (Valid)
      sys::fs::remove(Path);
  }
};

} // namespace

extern "C" {

void AMDGPUGetLLVMVersion(unsigned *Major, unsigned *Minor, unsigned *Patch) {
  if (Major) *Major = LLVM_VERSION_MAJOR;
  if (Minor) *Minor = LLVM_VERSION_MINOR;
  if (Patch) *Patch = LLVM_VERSION_PATCH;
}

void AMDGPUDisposeMessage(char *Message) { std::free(Message); }

const char *AMDGPUGetBufferStart(AMDGPUMemoryBufferRef Buffer) {
  return reinterpret_cast<MemoryBufferImpl *>(Buffer)->Data.data();
}
size_t AMDGPUGetBufferSize(AMDGPUMemoryBufferRef Buffer) {
  return reinterpret_cast<MemoryBufferImpl *>(Buffer)->Data.size();
}
void AMDGPUDisposeMemoryBuffer(AMDGPUMemoryBufferRef Buffer) {
  delete reinterpret_cast<MemoryBufferImpl *>(Buffer);
}

const char **AMDGPUGetProcessors(size_t *Count) {
  std::lock_guard<std::mutex> Guard(APILock);
  initializeTarget();
  // The keys point into the back-end's static tables, so the list is stable.
  static std::vector<const char *> Processors = [] {
    std::vector<const char *> R;
    auto STI = createSubtargetInfo(targetTriple());
    for (const SubtargetSubTypeKV &P : STI->getAllProcessorDescriptions())
      R.push_back(P.key());
    return R;
  }();
  if (Count) *Count = Processors.size();
  return Processors.data();
}

const char **AMDGPUGetFeatures(size_t *Count) {
  std::lock_guard<std::mutex> Guard(APILock);
  initializeTarget();
  static std::vector<const char *> Features = [] {
    std::vector<const char *> R;
    auto STI = createSubtargetInfo(targetTriple());
    for (const SubtargetFeatureKV &F : STI->getAllProcessorFeatures())
      R.push_back(F.key());
    return R;
  }();
  if (Count) *Count = Features.size();
  return Features.data();
}

const char *AMDGPUGetDataLayout(void) {
  std::lock_guard<std::mutex> Guard(APILock);
  initializeTarget();
  static std::string DL;
  if (DL.empty()) {
    Triple TT = targetTriple();
    std::unique_ptr<TargetMachine> TM(lookupTarget(TT).createTargetMachine(
        TT, "", "", TargetOptions(), std::nullopt));
    DL = TM->createDataLayout().getStringRepresentation();
  }
  return DL.c_str();
}

int AMDGPUCompile(const char *Bitcode, size_t Length,
                  const AMDGPUCompileOptions *Options,
                  AMDGPUDiagnosticCallback Handler, void *HandlerContext,
                  AMDGPUMemoryBufferRef *OutBuffer, char **OutMessage) {
  std::lock_guard<std::mutex> Guard(APILock);
  ScopedCLocale Locale;
  initializeTarget();
  if (OutMessage) *OutMessage = nullptr;
  if (OutBuffer) *OutBuffer = nullptr;

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
  Triple TT = targetTriple();
  const Target &TheTarget = lookupTarget(TT);
  std::string Features = Options->Features ? Options->Features : "";
  {
    auto STI = createSubtargetInfo(TT);
    if (!STI->isCPUStringValid(Options->CPU))
      return fail(std::string("'") + Options->CPU +
                  "' is not a recognized AMDGPU processor");
    std::string Unknown = checkFeatures(Features, *STI);
    if (!Unknown.empty())
      return fail("'" + Unknown + "' is not a recognized AMDGPU feature");
  }
  if (Options->OptLevel < 0 || Options->OptLevel > 3)
    return fail("invalid optimization level " +
                std::to_string(Options->OptLevel));
  CodeGenOptLevel OptLevel = static_cast<CodeGenOptLevel>(Options->OptLevel);
  CodeGenFileType FileType;
  switch (Options->FileType) {
  case AMDGPUAssemblyFile: FileType = CodeGenFileType::AssemblyFile; break;
  case AMDGPUObjectFile:   FileType = CodeGenFileType::ObjectFile;   break;
  default: return fail("invalid file type");
  }

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
    TO.MCOptions.AsmVerbose = true;
    S->TM.reset(TheTarget.createTargetMachine(TT, Options->CPU, Features, TO,
                                              Reloc::PIC_, std::nullopt,
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
          DH->emit(AMDGPUDSError, "error: " + SMD.getMessage().str());
          HasMCErrors = true;
        });
    raw_svector_ostream OS(S->Output);
    if (TM.addPassesToEmitFile(PM, OS, nullptr, FileType,
                               /*DisableVerify=*/true, MMIWP))
      return fail("target does not support generation of this file type");
    PM.run(M);
    if (!DH->Errors.empty() || HasMCErrors) {
      std::string Message = DH->Errors;
      if (!Message.empty() && Message.back() == '\n')
        Message.pop_back();
      return fail(Message);
    }

    if (OutBuffer)
      *OutBuffer = makeBuffer(S->Output.data(), S->Output.size());
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

int AMDGPULink(const char *Object, size_t Length,
               AMDGPUMemoryBufferRef *OutBuffer, char **OutMessage) {
  std::lock_guard<std::mutex> Guard(APILock);
  initializeTarget();
  if (OutMessage) *OutMessage = nullptr;
  if (OutBuffer) *OutBuffer = nullptr;
  auto fail = [&](const std::string &Message) {
    if (OutMessage) *OutMessage = makeMessage(Message);
    return 1;
  };

  // After a fatal error lld's global context is left as it was; it is torn
  // down here so the next link starts clean, and if even that fails the
  // linker is not used again.
  static bool Unusable = false;
  if (Unusable)
    return fail("lld is unusable after an earlier fatal error");

  TemporaryFile Input("amdgpu-link-input", "o");
  TemporaryFile Output("amdgpu-link-output", "so");
  if (!Input.Valid || !Output.Valid)
    return fail("cannot create temporary files for lld");
  {
    std::error_code EC;
    raw_fd_ostream OS(Input.Path, EC, sys::fs::OF_None);
    if (EC)
      return fail("cannot write " + Input.Path.str().str() + ": " + EC.message());
    OS.write(Object, Length);
  }

  std::string Log;
  lld::Result Result;
  {
    raw_string_ostream LogOS(Log);
    std::vector<const char *> Args = {"ld.lld", "-shared", "-o",
                                      Output.Path.c_str(), Input.Path.c_str()};
    Result = lld::lldMain(Args, LogOS, LogOS, {{lld::Gnu, &lld::elf::link}});
  }
  if (!Result.canRunAgain) {
    CrashRecoveryContext CRC;
    Unusable = !CRC.RunSafely([] { lld::CommonLinkerContext::destroy(); });
  }
  while (!Log.empty() && Log.back() == '\n')
    Log.pop_back();
  if (Result.retCode != 0)
    return fail(Log.empty() ? "lld failed" : Log);

  auto File = MemoryBuffer::getFile(Output.Path);
  if (!File)
    return fail("cannot read lld's output: " + File.getError().message());
  if (OutBuffer)
    *OutBuffer = makeBuffer((*File)->getBufferStart(), (*File)->getBufferSize());
  return 0;
}

} // extern "C"
