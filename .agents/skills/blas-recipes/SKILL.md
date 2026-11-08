---
name: blas-recipes
description: Rules for Yggdrasil recipes that call BLAS or LAPACK. Use when a build_tarballs.jl depends on libblastrampoline_jll, links -lblastrampoline, or calls BLAS/LAPACK with 64-bit integers (ILP64, `64_`-suffixed symbols).
---

# BLAS and LAPACK packages

Link `libblastrampoline_jll` (LBT), not a concrete BLAS. LBT forwards each call to the backend loaded into it at run time (OpenBLAS by default, MKL and others on request), so one build serves them all and no platform augmentation is needed.

```julia
script = raw"""
if [[ "${target}" == *-mingw* ]]; then
    LBT=blastrampoline-5
else
    LBT=blastrampoline
fi
# pass -l${LBT} to the build system
"""

dependencies = [
    Dependency("libblastrampoline_jll"; compat="5.4.0"),
]

build_tarballs(...; julia_compat="1.9")
```

- **Windows library name**: on Windows LBT installs only `libblastrampoline-5.dll` and its import library, so link `-lblastrampoline-5` there and `-lblastrampoline` elsewhere.
- **Compat follows Julia**: Julia ships `libblastrampoline_jll` as a standard library, so the `compat` bound must admit the version that every Julia in `julia_compat` ships: 5.1.1 in Julia 1.8, 5.7.0 in 1.9, 5.8.0 in 1.10, 5.11.0 in 1.11, 5.13.1 in 1.12 and 5.15.0 in 1.13. Julia 1.7 ships 3.0.4 and 1.6 none. `compat="5.4.0"` fits `julia_compat="1.9"`; `compat="5.11.0"` needs `julia_compat="1.11"`. Raise the lower bound only when the build needs a newer LBT, and raise `julia_compat` with it (see [`jll-versioning`](../jll-versioning/SKILL.md)).
- **ILP64**: LBT exports the LP64 (32-bit integer) interface under the usual names (`dgemm_`) and the ILP64 (64-bit integer) interface with a `64_` suffix (`dgemm_64_`). An ILP64 build must both use 64-bit integers and call the suffixed names, through the build system's symbol-suffix option, a header of `#define`s, or a patch. Julia's OpenBLAS is LP64 on 32-bit platforms, so build ILP64 only for 64-bit ones: `filter!(p -> nbits(p) == 64, platforms)`.
- **LP64 on 64-bit platforms**: Julia's default OpenBLAS fills only LBT's ILP64 interface there, so LP64 calls fail with `Error: no BLAS/LAPACK library loaded for dgemm_()` until something forwards an LP64 library. The Julia package does that in its `__init__`:

  ```julia
  config = LinearAlgebra.BLAS.lbt_get_config()
  if !any(lib -> lib.interface == :lp64, config.loaded_libs)
      LinearAlgebra.BLAS.lbt_forward(OpenBLAS32_jll.libopenblas_path)
  end
  ```

  When testing the JLL (see [`testing-jll`](../testing-jll/SKILL.md)), call a routine that reaches BLAS, with this forwarding in place for LP64 builds.
