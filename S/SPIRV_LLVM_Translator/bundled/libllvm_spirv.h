/*===-- libllvm_spirv.h - In-process Khronos SPIR-V translator ----*- C -*-===*\
|*                                                                            *|
|* A small, typed C API over a statically linked, symbol-hidden build of the  *|
|* Khronos SPIRV-LLVM-Translator (LLVM IR -> SPIR-V direction only). It       *|
|* replaces spawning the `llvm-spirv` executable: bitcode in, SPIR-V binary   *|
|* out, plus a query for the extensions the translator knows.                 *|
|*                                                                            *|
|* Conventions follow llvm-c: status as return value (0 = success), an error  *|
|* message returned through `OutMessage` only on failure (free it with        *|
|* LLVMSPIRVDisposeMessage), results as opaque memory buffers, and string     *|
|* lists owned by the library. Every call is serialised by an internal mutex. *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

#ifndef LIBLLVM_SPIRV_H
#define LIBLLVM_SPIRV_H

#include <stddef.h>

#if defined(_WIN32)
#define LLVMSPIRV_API __declspec(dllexport)
#else
#define LLVMSPIRV_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct LLVMSPIRVOpaqueMemoryBuffer *LLVMSPIRVMemoryBufferRef;

/* The `--spirv-debug-info-version` choices. */
typedef enum {
  LLVMSPIRVDebugInfoSPIRV = 0,                 /* "spirv-debug" (the default) */
  LLVMSPIRVDebugInfoOpenCL100 = 1,             /* "ocl-100" */
  LLVMSPIRVDebugInfoNonSemanticShader100 = 2,  /* "nonsemantic-shader-100" */
  LLVMSPIRVDebugInfoNonSemanticShader200 = 3   /* "nonsemantic-shader-200" */
} LLVMSPIRVDebugInfoVersion;

typedef struct {
  /* Highest SPIR-V version to emit (`--spirv-max-version`), e.g. 1 and 4.
   * 0/0 selects the translator's maximum. */
  unsigned MaxVersionMajor, MaxVersionMinor;
  /* Comma-separated extension list in `--spirv-ext` syntax: "+NAME" allows,
   * "-NAME" disallows, "all" stands for every known extension; a bare name
   * means "+NAME". NULL/"" allows none. Names are validated against
   * LLVMSPIRVGetExtensions; an unknown one is an error. */
  const char *Extensions;
  /* Debug info representation to emit. */
  LLVMSPIRVDebugInfoVersion DebugInfoVersion;
} LLVMSPIRVTranslateOptions;

/* Translate a module (bitcode or textual IR, `Length` bytes at `Bitcode`,
 * targeting spir64/spir-unknown-unknown as its own triple says) to a SPIR-V
 * binary. Bitcode from any LLVM older than the one embedded is auto-upgraded
 * on load. On success returns 0 and sets `*OutSPIRV`; on failure returns
 * nonzero and sets `*OutMessage`. A fatal LLVM error (`report_fatal_error`)
 * is reported the same way and leaves the library usable, at the cost of
 * leaking that call's state. */
LLVMSPIRV_API int LLVMSPIRVTranslate(const char *Bitcode, size_t Length,
                                     const LLVMSPIRVTranslateOptions *Options,
                                     LLVMSPIRVMemoryBufferRef *OutSPIRV,
                                     char **OutMessage);

/* Queries. Lists are owned by the library, valid for its lifetime. */
LLVMSPIRV_API const char **LLVMSPIRVGetExtensions(size_t *Count);
LLVMSPIRV_API void LLVMSPIRVGetLLVMVersion(unsigned *Major, unsigned *Minor,
                                           unsigned *Patch);

/* Memory management. */
LLVMSPIRV_API const char *LLVMSPIRVGetBufferStart(LLVMSPIRVMemoryBufferRef Buffer);
LLVMSPIRV_API size_t LLVMSPIRVGetBufferSize(LLVMSPIRVMemoryBufferRef Buffer);
LLVMSPIRV_API void LLVMSPIRVDisposeMemoryBuffer(LLVMSPIRVMemoryBufferRef Buffer);
LLVMSPIRV_API void LLVMSPIRVDisposeMessage(char *Message);

#ifdef __cplusplus
}
#endif

#endif /* LIBLLVM_SPIRV_H */
