//===-- libllvm_spirv.cpp - In-process Khronos SPIR-V translator ----------===//
//
// Implements the C API in libllvm_spirv.h on top of LLVMSPIRVLib: what
// `llvm-spirv --spirv-max-version=X.Y --spirv-ext=... --spirv-debug-info-version=...`
// does, without the driver, the command-line parser, or the file system. The
// translator takes all its options as a `SPIRV::TranslatorOpts` struct, so this
// is a direct mapping.
//
// No `cl::opt` is registered by this file. All LLVM and translator symbols are
// hidden at link time, so the library loads next to Julia's own LLVM (or a
// sibling back-end library) in one process.
//
//===----------------------------------------------------------------------===//

#include "libllvm_spirv.h"

#include "LLVMSPIRVLib.h"
#include "LLVMSPIRVOpts.h"
#include "llvm/Config/llvm-config.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/PrettyStackTrace.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

#include <cstdlib>
#include <cstring>
#include <map>
#include <mutex>
#include <sstream>
#include <string>
#include <vector>

using namespace llvm;

namespace {

std::mutex APILock;

// `report_fatal_error` is turned into a C++ exception so the caller gets a
// message instead of an abort. The unwind passes through frames compiled with
// -fno-exceptions, whose cleanups are skipped, so the state of the failing
// call must not be destroyed afterwards (see `State` below).
struct FatalError {
  std::string Message;
};
[[noreturn]] void throwingFatalErrorHandler(void *, const char *Reason, bool) {
  throw FatalError{Reason};
}

struct MemoryBufferImpl {
  std::string Data;
};

// Everything owned by one translation, in one heap block: deleted on a normal
// return, deliberately leaked after a recovered fatal error.
struct State {
  LLVMContext Context;
  std::unique_ptr<Module> M;
  std::ostringstream Output;
};

char *makeMessage(const std::string &S) {
  char *P = static_cast<char *>(std::malloc(S.size() + 1));
  if (P)
    std::memcpy(P, S.c_str(), S.size() + 1);
  return P;
}

const std::map<std::string, SPIRV::ExtensionID> &extensionsByName() {
  static const std::map<std::string, SPIRV::ExtensionID> Map = [] {
    std::map<std::string, SPIRV::ExtensionID> M;
#define EXT(X) M[#X] = SPIRV::ExtensionID::X;
#include "LLVMSPIRVExtensions.inc"
#undef EXT
    return M;
  }();
  return Map;
}

// Parses the option's extension list like llvm-spirv's parseSPVExtOption;
// returns an error message, or empty.
std::string parseExtensions(const char *List,
                            SPIRV::TranslatorOpts::ExtensionsStatusMap &Status) {
  const auto &Known = extensionsByName();
  // Generating SPIR-V: every known extension starts out disallowed.
  for (const auto &KV : Known)
    Status[KV.second] = std::nullopt;
  if (!List || !*List)
    return std::string();
  SmallVector<StringRef, 8> Tokens;
  StringRef(List).split(Tokens, ',', -1, /*KeepEmpty=*/false);
  for (StringRef Token : Tokens) {
    Token = Token.trim();
    bool Allow = true;
    if (Token.starts_with("+") || Token.starts_with("-")) {
      Allow = Token[0] == '+';
      Token = Token.drop_front();
    }
    if (Token.empty())
      return "invalid extension list entry";
    if (Token == "all") {
      for (const auto &KV : Known)
        Status[KV.second] = Allow;
      continue;
    }
    auto It = Known.find(Token.str());
    if (It == Known.end())
      return "unknown SPIR-V extension: " + Token.str();
    Status[It->second] = Allow;
  }
  return std::string();
}

} // namespace

extern "C" {

void LLVMSPIRVGetLLVMVersion(unsigned *Major, unsigned *Minor, unsigned *Patch) {
  if (Major) *Major = LLVM_VERSION_MAJOR;
  if (Minor) *Minor = LLVM_VERSION_MINOR;
  if (Patch) *Patch = LLVM_VERSION_PATCH;
}

void LLVMSPIRVDisposeMessage(char *Message) { std::free(Message); }

const char *LLVMSPIRVGetBufferStart(LLVMSPIRVMemoryBufferRef Buffer) {
  return reinterpret_cast<MemoryBufferImpl *>(Buffer)->Data.data();
}
size_t LLVMSPIRVGetBufferSize(LLVMSPIRVMemoryBufferRef Buffer) {
  return reinterpret_cast<MemoryBufferImpl *>(Buffer)->Data.size();
}
void LLVMSPIRVDisposeMemoryBuffer(LLVMSPIRVMemoryBufferRef Buffer) {
  delete reinterpret_cast<MemoryBufferImpl *>(Buffer);
}

const char **LLVMSPIRVGetExtensions(size_t *Count) {
  std::lock_guard<std::mutex> Guard(APILock);
  static std::vector<const char *> Names = [] {
    std::vector<const char *> R;
    for (const auto &KV : extensionsByName())
      R.push_back(KV.first.c_str()); // the map is static: stable
    return R;
  }();
  if (Count) *Count = Names.size();
  return Names.data();
}

int LLVMSPIRVTranslate(const char *Bitcode, size_t Length,
                       const LLVMSPIRVTranslateOptions *Options,
                       LLVMSPIRVMemoryBufferRef *OutSPIRV, char **OutMessage) {
  std::lock_guard<std::mutex> Guard(APILock);
  if (OutMessage) *OutMessage = nullptr;
  if (OutSPIRV) *OutSPIRV = nullptr;

  State *S = nullptr;
  auto fail = [&](const std::string &Message) {
    if (OutMessage) *OutMessage = makeMessage(Message);
    delete S;
    S = nullptr;
    return 1;
  };

  // 1. Options, as llvm-spirv derives them from its flags.
  if (!Options)
    return fail("no options given");
  SPIRV::VersionNumber MaxVersion = SPIRV::VersionNumber::MaximumVersion;
  if (Options->MaxVersionMajor != 0 || Options->MaxVersionMinor != 0) {
    MaxVersion = static_cast<SPIRV::VersionNumber>(
        (Options->MaxVersionMajor << 16) | (Options->MaxVersionMinor << 8));
    if (!SPIRV::isSPIRVVersionKnown(MaxVersion))
      return fail("unsupported SPIR-V version " +
                  std::to_string(Options->MaxVersionMajor) + "." +
                  std::to_string(Options->MaxVersionMinor));
  }
  SPIRV::TranslatorOpts::ExtensionsStatusMap Extensions;
  {
    std::string Error = parseExtensions(Options->Extensions, Extensions);
    if (!Error.empty())
      return fail(Error);
  }
  SPIRV::TranslatorOpts Opts(MaxVersion, Extensions);
  switch (Options->DebugInfoVersion) {
  case LLVMSPIRVDebugInfoSPIRV:
    Opts.setDebugInfoEIS(SPIRV::DebugInfoEIS::SPIRV_Debug);
    break;
  case LLVMSPIRVDebugInfoOpenCL100:
    Opts.setDebugInfoEIS(SPIRV::DebugInfoEIS::OpenCL_DebugInfo_100);
    break;
  case LLVMSPIRVDebugInfoNonSemanticShader100:
    Opts.setDebugInfoEIS(SPIRV::DebugInfoEIS::NonSemantic_Shader_DebugInfo_100);
    Opts.setAllowedToUseExtension(SPIRV::ExtensionID::SPV_KHR_non_semantic_info);
    break;
  case LLVMSPIRVDebugInfoNonSemanticShader200:
    Opts.setDebugInfoEIS(SPIRV::DebugInfoEIS::NonSemantic_Shader_DebugInfo_200);
    Opts.setAllowExtraDIExpressionsEnabled(true);
    Opts.setAllowedToUseExtension(SPIRV::ExtensionID::SPV_KHR_non_semantic_info);
    break;
  default:
    return fail("invalid debug info version");
  }

  // 2. Translate. `State` is leaked after a fatal error (see above), and the
  //    thread-local pretty-stack list is repaired since its RAII entries
  //    were skipped by the unwind too.
  S = new State;
  const void *PrettyStack = SavePrettyStackState();
  ScopedFatalErrorHandler FatalGuard(throwingFatalErrorHandler);
  try {
    // The IR parser requires a null-terminated buffer: copy.
    SMDiagnostic ParseError;
    auto Buffer = MemoryBuffer::getMemBufferCopy(StringRef(Bitcode, Length),
                                                 "<input>");
    S->M = parseIR(Buffer->getMemBufferRef(), ParseError, S->Context);
    if (!S->M) {
      std::string Message;
      raw_string_ostream OS(Message);
      ParseError.print(nullptr, OS, false);
      if (!Message.empty() && Message.back() == '\n')
        Message.pop_back();
      return fail(Message);
    }

    std::string Error;
    if (!writeSpirv(S->M.get(), Opts, S->Output, Error))
      return fail(Error.empty() ? "SPIR-V translation failed" : Error);

    auto *Out = new MemoryBufferImpl;
    Out->Data = S->Output.str();
    if (OutSPIRV)
      *OutSPIRV = reinterpret_cast<LLVMSPIRVMemoryBufferRef>(Out);
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
