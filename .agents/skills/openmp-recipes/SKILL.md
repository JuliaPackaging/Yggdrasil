---
name: openmp-recipes
description: Rules for Yggdrasil recipes that use OpenMP. Use when a build_tarballs.jl compiles with -fopenmp or enables an OpenMP option, links libgomp or libomp, or depends on LLVMOpenMP_jll.
---

# OpenMP packages

The OpenMP runtime follows the compiler. BinaryBuilder compiles C and C++ with Clang on macOS and FreeBSD, which needs libomp from `LLVMOpenMP_jll`, and with GCC elsewhere, which needs libgomp from `CompilerSupportLibraries_jll`:

```julia
dependencies = [
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isbsd, platforms)),
    Dependency("LLVMOpenMP_jll"; platforms=filter(Sys.isbsd, platforms)),
]
```

Both still need a `compat` bound; see below.

- **Build system**: pass upstream's OpenMP option and let it add `-fopenmp`. CMake's `FindOpenMP` finds both runtimes without `OpenMP_*` variables. A plain Makefile on macOS and FreeBSD needs `-fopenmp -I${includedir}` to compile and `-L${libdir} -lomp` to link.
- **Never mix runtimes**: compile against the `omp.h` of the runtime you link. Don't copy an `omp.h` from elsewhere, link `-lgomp` with Clang, or use `-fopenmp=libgomp`.
- **Fortran**: gfortran always uses libgomp, so OpenMP Fortran code needs `CompilerSupportLibraries_jll` on every platform, macOS and FreeBSD included.
- **`LLVMOpenMP_jll` compat**: BinaryBuilder compiles with the newest Clang unless `preferred_llvm_version` says otherwise, but builds against the oldest libomp the bound admits. That libomp must export every `__kmpc_*` entry point the Clang emits; for example, Clang 19 and later emit `__kmpc_dispatch_deinit`, which libomp before 19 lacks. When linking or loading fails on an undefined `__kmpc_*` symbol, raise the lower bound to the first release whose `openmp/runtime/src/dllexports` lists it.
- **`CompilerSupportLibraries_jll` compat** is limited by `julia_compat`; see [`fortran-recipes`](../fortran-recipes/SKILL.md#compilersupportlibraries_jll-compat).
