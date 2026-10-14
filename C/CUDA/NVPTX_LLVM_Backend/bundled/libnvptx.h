/*===-- libnvptx.h - In-process NVPTX back-end for GPUCompiler ----*- C -*-===*\
|*                                                                            *|
|* A small, typed C API over a statically linked, symbol-hidden LLVM NVPTX    *|
|* back-end. It replaces spawning the `llc` executable: bitcode in, PTX out,  *|
|* plus queries for what the back-end supports so callers don't hand-maintain *|
|* tables keyed on the JLL version.                                           *|
|*                                                                            *|
|* Conventions follow llvm-c: status as return value (0 = success), an error  *|
|* message returned through `OutMessage` only on failure (free it with        *|
|* NVPTXDisposeMessage), results as opaque memory buffers, and string lists   *|
|* owned by the library. Every call is serialised by an internal mutex.       *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

#ifndef LIBNVPTX_H
#define LIBNVPTX_H

#include <stddef.h>

#if defined(_WIN32)
#define NVPTX_API __declspec(dllexport)
#else
#define NVPTX_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct NVPTXOpaqueMemoryBuffer *NVPTXMemoryBufferRef;

typedef enum {
  NVPTXDSError = 0,
  NVPTXDSWarning = 1,
  NVPTXDSRemark = 2,
  NVPTXDSNote = 3
} NVPTXDiagnosticSeverity;

/* Receives every diagnostic the back-end emits, formatted as `llc` would print
 * it (without the trailing newline). NULL means: print to stderr. Errors are
 * also collected into the failure message returned by NVPTXCompile. */
typedef void (*NVPTXDiagnosticCallback)(NVPTXDiagnosticSeverity Severity,
                                        const char *Message, void *Context);

typedef struct {
  /* Target processor, e.g. "sm_90a". Validated against the back-end's table
   * (see NVPTXGetProcessors); an unknown name is an error, not a fallback. */
  const char *CPU;
  /* PTX ISA version, e.g. 8 and 5 for "+ptx85". 0/0 selects the back-end's
   * default for the processor. Validated against NVPTXGetPTXVersions. */
  unsigned PTXMajor, PTXMinor;
  /* Whether to target nvptx64 (1) or nvptx (0). */
  int Is64Bit;
  /* Code generation optimisation level, 0..3. `llc` defaults to 2. */
  int OptLevel;
  /* Allow FP contraction into fma (what `-nvptx-fma-level=1` used to do). */
  int FMAContraction;
  /* Emit assembler comments, like `llc -asm-verbose` (its default). */
  int Verbose;
} NVPTXCompileOptions;

/* Compile a module (bitcode or textual IR, `Length` bytes at `Bitcode`) to PTX
 * text. Bitcode from any LLVM older than the one embedded is auto-upgraded on
 * load. The module's own triple and datalayout are overridden by the target's.
 * On success returns 0 and sets `*OutPTX`; on failure returns nonzero and sets
 * `*OutMessage`. A fatal LLVM error (`report_fatal_error`) is reported the same
 * way and leaves the library usable, at the cost of leaking that call's state. */
NVPTX_API int NVPTXCompile(const char *Bitcode, size_t Length,
                           const NVPTXCompileOptions *Options,
                           NVPTXDiagnosticCallback Handler, void *HandlerContext,
                           NVPTXMemoryBufferRef *OutPTX, char **OutMessage);

/* Queries. Lists are owned by the library, valid for its lifetime. */
NVPTX_API const char **NVPTXGetProcessors(size_t *Count);  /* "sm_20", ... */
NVPTX_API const char **NVPTXGetPTXVersions(size_t *Count); /* "ptx32", ... */
NVPTX_API const char *NVPTXGetDataLayout(int Is64Bit);
NVPTX_API void NVPTXGetLLVMVersion(unsigned *Major, unsigned *Minor,
                                   unsigned *Patch);

/* Memory management. */
NVPTX_API const char *NVPTXGetBufferStart(NVPTXMemoryBufferRef Buffer);
NVPTX_API size_t NVPTXGetBufferSize(NVPTXMemoryBufferRef Buffer);
NVPTX_API void NVPTXDisposeMemoryBuffer(NVPTXMemoryBufferRef Buffer);
NVPTX_API void NVPTXDisposeMessage(char *Message);

#ifdef __cplusplus
}
#endif

#endif /* LIBNVPTX_H */
