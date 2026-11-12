/*===-- libspirv.h - In-process SPIR-V back-end for GPUCompiler ---*- C -*-===*\
|*                                                                            *|
|* A small, typed C API over a statically linked, symbol-hidden LLVM SPIR-V   *|
|* back-end. It replaces spawning the `llc` executable: bitcode in, SPIR-V    *|
|* binary out, plus queries for what the back-end supports.                   *|
|*                                                                            *|
|* Conventions follow llvm-c: status as return value (0 = success), an error  *|
|* message returned through `OutMessage` only on failure (free it with        *|
|* SPIRVDisposeMessage), results as opaque memory buffers, and string lists   *|
|* owned by the library. Every call is serialised by an internal mutex.       *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

#ifndef LIBSPIRV_H
#define LIBSPIRV_H

#include <stddef.h>

#if defined(_WIN32)
#define SPIRV_API __declspec(dllexport)
#else
#define SPIRV_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct SPIRVOpaqueMemoryBuffer *SPIRVMemoryBufferRef;

typedef enum {
  SPIRVDSError = 0,
  SPIRVDSWarning = 1,
  SPIRVDSRemark = 2,
  SPIRVDSNote = 3
} SPIRVDiagnosticSeverity;

/* Receives every diagnostic the back-end emits, formatted as `llc` would print
 * it (without the trailing newline). NULL means: print to stderr. Errors are
 * also collected into the failure message returned by SPIRVCompile. */
typedef void (*SPIRVDiagnosticCallback)(SPIRVDiagnosticSeverity Severity,
                                        const char *Message, void *Context);

typedef struct {
  /* Whether to target spirv64 (1) or spirv32 (0). */
  int Is64Bit;
  /* SPIR-V version to emit, e.g. 1 and 5 for the `spirv64v1.5` triple.
   * 0/0 selects the back-end's default. */
  unsigned VersionMajor, VersionMinor;
  /* Comma-separated extension names to allow, e.g.
   * "SPV_KHR_bit_instructions,SPV_INTEL_subgroups" (a leading '+' per name is
   * accepted), or "all" for every extension the back-end knows for the target
   * environment. NULL/"" allows none. Names are validated against
   * SPIRVGetExtensions; an unknown one is an error. */
  const char *Extensions;
  /* Code generation optimisation level, 0..3. `llc` defaults to 2. */
  int OptLevel;
} SPIRVCompileOptions;

/* Compile a module (bitcode or textual IR, `Length` bytes at `Bitcode`) to a
 * SPIR-V binary (what `llc -filetype=obj` produces). Bitcode from any LLVM
 * older than the one embedded is auto-upgraded on load. The module's own
 * triple and datalayout are overridden by the target's. On success returns 0
 * and sets `*OutSPIRV`; on failure returns nonzero and sets `*OutMessage`. A
 * fatal LLVM error (`report_fatal_error`) is reported the same way and leaves
 * the library usable, at the cost of leaking that call's state. */
SPIRV_API int SPIRVCompile(const char *Bitcode, size_t Length,
                           const SPIRVCompileOptions *Options,
                           SPIRVDiagnosticCallback Handler, void *HandlerContext,
                           SPIRVMemoryBufferRef *OutSPIRV, char **OutMessage);

/* Queries. Lists are owned by the library, valid for its lifetime. The
 * extension list is for the OpenCL environment (the `*-unknown-unknown`
 * triples), the one this library targets. */
SPIRV_API const char **SPIRVGetExtensions(size_t *Count); /* "SPV_KHR_...", ... */
SPIRV_API const char *SPIRVGetDataLayout(int Is64Bit);
SPIRV_API void SPIRVGetLLVMVersion(unsigned *Major, unsigned *Minor,
                                   unsigned *Patch);

/* Memory management. */
SPIRV_API const char *SPIRVGetBufferStart(SPIRVMemoryBufferRef Buffer);
SPIRV_API size_t SPIRVGetBufferSize(SPIRVMemoryBufferRef Buffer);
SPIRV_API void SPIRVDisposeMemoryBuffer(SPIRVMemoryBufferRef Buffer);
SPIRV_API void SPIRVDisposeMessage(char *Message);

#ifdef __cplusplus
}
#endif

#endif /* LIBSPIRV_H */
