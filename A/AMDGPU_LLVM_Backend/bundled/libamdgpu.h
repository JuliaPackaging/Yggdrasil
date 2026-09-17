/*===-- libamdgpu.h - In-process AMDGPU back-end for GPUCompiler --*- C -*-===*\
|*                                                                            *|
|* A small, typed C API over a statically linked, symbol-hidden LLVM AMDGPU   *|
|* back-end and lld. It replaces spawning the `llc` and `lld` executables:    *|
|* bitcode in, assembly or ELF object out, and object in, HSA code object     *|
|* out; plus queries for what the back-end supports.                          *|
|*                                                                            *|
|* Conventions follow llvm-c: status as return value (0 = success), an error  *|
|* message returned through `OutMessage` only on failure (free it with        *|
|* AMDGPUDisposeMessage), results as opaque memory buffers, and string lists  *|
|* owned by the library. Every call is serialised by an internal mutex.       *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

#ifndef LIBAMDGPU_H
#define LIBAMDGPU_H

#include <stddef.h>

#if defined(_WIN32)
#define AMDGPU_API __declspec(dllexport)
#else
#define AMDGPU_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct AMDGPUOpaqueMemoryBuffer *AMDGPUMemoryBufferRef;

typedef enum {
  AMDGPUDSError = 0,
  AMDGPUDSWarning = 1,
  AMDGPUDSRemark = 2,
  AMDGPUDSNote = 3
} AMDGPUDiagnosticSeverity;

/* Receives every diagnostic the back-end emits, formatted as `llc` would print
 * it (without the trailing newline). NULL means: print to stderr. Errors are
 * also collected into the failure message returned by AMDGPUCompile. */
typedef void (*AMDGPUDiagnosticCallback)(AMDGPUDiagnosticSeverity Severity,
                                         const char *Message, void *Context);

typedef enum {
  AMDGPUAssemblyFile = 0,
  AMDGPUObjectFile = 1
} AMDGPUFileType;

typedef struct {
  /* Target processor, e.g. "gfx90a". Validated against the back-end's table
   * (see AMDGPUGetProcessors); an unknown name is an error, not a fallback. */
  const char *CPU;
  /* Comma-separated subtarget features, e.g. "+wavefrontsize64,-wavefrontsize32",
   * or NULL/"" for the processor's defaults. Every name is validated against
   * AMDGPUGetFeatures. */
  const char *Features;
  /* Code generation optimisation level, 0..3. `llc` defaults to 2. */
  int OptLevel;
  /* Assembly text or a relocatable ELF object (for AMDGPULink). */
  AMDGPUFileType FileType;
} AMDGPUCompileOptions;

/* Compile a module (bitcode or textual IR, `Length` bytes at `Bitcode`) for
 * amdgcn-amd-amdhsa with the PIC relocation model. Bitcode from any LLVM older
 * than the one embedded is auto-upgraded on load. The module's own triple and
 * datalayout are overridden by the target's. On success returns 0 and sets
 * `*OutBuffer`; on failure returns nonzero and sets `*OutMessage`. A fatal LLVM
 * error (`report_fatal_error`) is reported the same way and leaves the library
 * usable, at the cost of leaking that call's state. */
AMDGPU_API int AMDGPUCompile(const char *Bitcode, size_t Length,
                             const AMDGPUCompileOptions *Options,
                             AMDGPUDiagnosticCallback Handler,
                             void *HandlerContext,
                             AMDGPUMemoryBufferRef *OutBuffer,
                             char **OutMessage);

/* Link one relocatable object into an HSA code object, as
 * `ld.lld -flavor gnu -shared -o <out> <in>` does, in-process. lld's output
 * (warnings, errors) is returned through `*OutMessage` on failure. The library
 * stages the input and output through temporary files; callers never do. */
AMDGPU_API int AMDGPULink(const char *Object, size_t Length,
                          AMDGPUMemoryBufferRef *OutBuffer, char **OutMessage);

/* Queries. Lists are owned by the library, valid for its lifetime. */
AMDGPU_API const char **AMDGPUGetProcessors(size_t *Count); /* "gfx900", ... */
AMDGPU_API const char **AMDGPUGetFeatures(size_t *Count);   /* "wavefrontsize64", ... */
AMDGPU_API const char *AMDGPUGetDataLayout(void);
AMDGPU_API void AMDGPUGetLLVMVersion(unsigned *Major, unsigned *Minor,
                                     unsigned *Patch);

/* Memory management. */
AMDGPU_API const char *AMDGPUGetBufferStart(AMDGPUMemoryBufferRef Buffer);
AMDGPU_API size_t AMDGPUGetBufferSize(AMDGPUMemoryBufferRef Buffer);
AMDGPU_API void AMDGPUDisposeMemoryBuffer(AMDGPUMemoryBufferRef Buffer);
AMDGPU_API void AMDGPUDisposeMessage(char *Message);

#ifdef __cplusplus
}
#endif

#endif /* LIBAMDGPU_H */
