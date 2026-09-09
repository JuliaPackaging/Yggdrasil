//===-- libspirv.cpp - In-process SPIR-V back-end for GPUCompiler ---------===//
//
// Implements the C API in libspirv.h on top of LLVM's SPIR-V back-end: what
// `llc -mtriple=spirv64[vX.Y]-unknown-unknown -filetype=obj [-spirv-ext=...]`
// does, without the driver, the command-line parser, or the file system.
//
// Extensions are applied per target machine through the back-end's own
// `SPIRVSubtarget::initAvailableExtensions`, the way LLVM's in-tree
// `SPIRVTranslateModule` does it, rather than through the global `-spirv-ext`
// option; so no `cl::opt` is registered or mutated by this file. That keeps the
// library loadable next to another LLVM (Julia's own, or a sibling back-end
// library) in one process: all LLVM symbols are hidden at link time, and the
// only global state LLVM touches is its own private copy.
//
// This is built in-tree: it needs the back-end's private headers.
//
//===----------------------------------------------------------------------===//

#include "libspirv.h"

#include "MCTargetDesc/SPIRVBaseInfo.h"
#include "SPIRVCommandLine.h"
#include "SPIRVSubtarget.h"
#include "SPIRVTargetMachine.h"
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
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/CodeGen.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/PrettyStackTrace.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/TargetParser/Triple.h"

#include <cstdlib>
#include <cstring>
#include <mutex>
#include <string>
#include <vector>

using namespace llvm;

namespace {

std::mutex APILock;

void initializeTarget() {
  static std::once_flag Once;
  std::call_once(Once, [] {
    LLVMInitializeSPIRVTargetInfo();
    LLVMInitializeSPIRVTarget();
    LLVMInitializeSPIRVTargetMC();
    LLVMInitializeSPIRVAsmPrinter();
  });
}

// spirv64-unknown-unknown, optionally with a version sub-architecture.
Triple targetTriple(bool Is64Bit, unsigned Major, unsigned Minor) {
  std::string Arch = Is64Bit ? "spirv64" : "spirv32";
  if (Major != 0 || Minor != 0)
    Arch += "v" + std::to_string(Major) + "." + std::to_string(Minor);
  return Triple(Arch + "-unknown-unknown");
}

const Target &lookupTarget(const Triple &TT) {
  std::string Error;
  const Target *T = TargetRegistry::lookupTarget(TT, Error);
  if (!T)
    report_fatal_error(Twine("SPIR-V target not registered: ") + Error);
  return *T;
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

// Formats diagnostics exactly like llc's LLCDiagnosticHandler and routes them
// to the user's callback, remembering errors for the failure message.
struct CallbackDiagnosticHandler : public DiagnosticHandler {
  SPIRVDiagnosticCallback Callback;
  void *Context;
  std::string Errors;

  CallbackDiagnosticHandler(SPIRVDiagnosticCallback CB, void *Ctx)
      : Callback(CB), Context(Ctx) {}

  void emit(SPIRVDiagnosticSeverity Severity, const std::string &Message) {
    if (Severity == SPIRVDSError)
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
    SPIRVDiagnosticSeverity Severity = SPIRVDSError;
    switch (DI.getSeverity()) {
    case DS_Warning: Severity = SPIRVDSWarning; break;
    case DS_Remark:  Severity = SPIRVDSRemark;  break;
    case DS_Note:    Severity = SPIRVDSNote;    break;
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

// Parses the option's extension list into the back-end's enum set; returns an
// error message, or empty.
std::string parseExtensions(const char *List, const Triple &TT,
                            ExtensionSet &Allowed) {
  if (!List || !*List)
    return std::string();
  SmallVector<StringRef, 8> Tokens;
  StringRef(List).split(Tokens, ',', -1, /*KeepEmpty=*/false);
  std::vector<std::string> Names;
  for (StringRef Token : Tokens) {
    Token = Token.trim();
    if (Token == "all") {
      Allowed = SPIRVExtensionsParser::getValidExtensions(TT);
      continue;
    }
    if (Token.starts_with("+"))
      Token = Token.drop_front();
    if (Token.empty() || Token.starts_with("-"))
      return "invalid extension list entry '" + Token.str() + "'";
    Names.push_back(Token.str());
  }
  StringRef Unknown = SPIRVExtensionsParser::checkExtensions(Names, Allowed);
  if (!Unknown.empty())
    return "unknown SPIR-V extension: " + Unknown.str();
  return std::string();
}

} // namespace

extern "C" {

void SPIRVGetLLVMVersion(unsigned *Major, unsigned *Minor, unsigned *Patch) {
  if (Major) *Major = LLVM_VERSION_MAJOR;
  if (Minor) *Minor = LLVM_VERSION_MINOR;
  if (Patch) *Patch = LLVM_VERSION_PATCH;
}

void SPIRVDisposeMessage(char *Message) { std::free(Message); }

const char *SPIRVGetBufferStart(SPIRVMemoryBufferRef Buffer) {
  return reinterpret_cast<MemoryBufferImpl *>(Buffer)->Data.data();
}
size_t SPIRVGetBufferSize(SPIRVMemoryBufferRef Buffer) {
  return reinterpret_cast<MemoryBufferImpl *>(Buffer)->Data.size();
}
void SPIRVDisposeMemoryBuffer(SPIRVMemoryBufferRef Buffer) {
  delete reinterpret_cast<MemoryBufferImpl *>(Buffer);
}

const char **SPIRVGetExtensions(size_t *Count) {
  std::lock_guard<std::mutex> Guard(APILock);
  static std::vector<std::string> Names;
  static std::vector<const char *> Pointers = [] {
    for (SPIRV::Extension::Extension E :
         SPIRVExtensionsParser::getValidExtensions(targetTriple(true, 0, 0)))
      Names.push_back(getSymbolicOperandMnemonic(
          SPIRV::OperandCategory::ExtensionOperand, E));
    std::vector<const char *> R;
    for (const std::string &N : Names)
      R.push_back(N.c_str());
    return R;
  }();
  if (Count) *Count = Pointers.size();
  return Pointers.data();
}

const char *SPIRVGetDataLayout(int Is64Bit) {
  std::lock_guard<std::mutex> Guard(APILock);
  initializeTarget();
  static std::string Layouts[2];
  std::string &DL = Layouts[Is64Bit ? 1 : 0];
  if (DL.empty()) {
    Triple TT = targetTriple(Is64Bit, 0, 0);
    std::unique_ptr<TargetMachine> TM(lookupTarget(TT).createTargetMachine(
        TT, "", "", TargetOptions(), std::nullopt));
    DL = TM->createDataLayout().getStringRepresentation();
  }
  return DL.c_str();
}

int SPIRVCompile(const char *Bitcode, size_t Length,
                 const SPIRVCompileOptions *Options,
                 SPIRVDiagnosticCallback Handler, void *HandlerContext,
                 SPIRVMemoryBufferRef *OutSPIRV, char **OutMessage) {
  std::lock_guard<std::mutex> Guard(APILock);
  initializeTarget();
  if (OutMessage) *OutMessage = nullptr;
  if (OutSPIRV) *OutSPIRV = nullptr;

  State *S = nullptr;
  auto fail = [&](const std::string &Message) {
    if (OutMessage) *OutMessage = makeMessage(Message);
    delete S;
    S = nullptr;
    return 1;
  };

  // 1. Validate the options.
  if (!Options)
    return fail("no options given");
  Triple TT = targetTriple(Options->Is64Bit, Options->VersionMajor,
                           Options->VersionMinor);
  if ((Options->VersionMajor != 0 || Options->VersionMinor != 0) &&
      TT.getSubArch() == Triple::NoSubArch)
    return fail("unsupported SPIR-V version " +
                std::to_string(Options->VersionMajor) + "." +
                std::to_string(Options->VersionMinor));
  const Target &TheTarget = lookupTarget(TT);
  ExtensionSet Extensions;
  {
    std::string Error = parseExtensions(Options->Extensions, TT, Extensions);
    if (!Error.empty())
      return fail(Error);
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

    // Target machine, with the allowed extensions set on its subtarget. The
    // module's triple and datalayout are the target's, whatever it claimed.
    S->TM.reset(TheTarget.createTargetMachine(TT, "", "", TargetOptions(),
                                              std::nullopt, std::nullopt,
                                              OptLevel));
    TargetMachine &TM = *S->TM;
    const_cast<SPIRVSubtarget *>(
        static_cast<SPIRVTargetMachine &>(TM).getSubtargetImpl())
        ->initAvailableExtensions(Extensions);
    M.setTargetTriple(TT);
    M.setDataLayout(TM.createDataLayout());

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
          DH->emit(SPIRVDSError, "error: " + SMD.getMessage().str());
          HasMCErrors = true;
        });
    raw_svector_ostream OS(S->Output);
    if (TM.addPassesToEmitFile(PM, OS, nullptr, CodeGenFileType::ObjectFile,
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
    if (OutSPIRV)
      *OutSPIRV = reinterpret_cast<SPIRVMemoryBufferRef>(Out);
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
  }
}

} // extern "C"
