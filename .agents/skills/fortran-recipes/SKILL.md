---
name: fortran-recipes
description: Rules for Yggdrasil recipes that compile Fortran or link libgfortran or libgomp. Use when a build_tarballs.jl uses ${FC} or gfortran, calls expand_gfortran_versions, filters on libgfortran_version, or depends on CompilerSupportLibraries_jll.
---

# Fortran packages

Anything linking libgfortran needs `platforms = expand_gfortran_versions(platforms)` and `Dependency("CompilerSupportLibraries_jll")`, which ships libgfortran to users.

## GCC version

`expand_gfortran_versions` adds one variant per libgfortran ABI, and each ABI fixes the GCC series that builds it:

| libgfortran | GCC |
|---|---|
| 3 | 4.8.5, 5.2, 6.1 |
| 4 | 7.1 |
| 5 | 8.1 and later |

`preferred_gcc_version` selects the closest GCC within a variant's series, so `preferred_gcc_version=v"10"` still builds the libgfortran 3 variants with GCC 6 and the libgfortran 4 variants with GCC 7, without warning. Code that needs a newer compiler fails only on those variants. Drop them after expanding, saying what fails:

```julia
platforms = expand_gfortran_versions(supported_platforms())
# Needs C++17
filter!(p -> libgfortran_version(p) >= v"5", platforms)
```

## Argument mismatch

gfortran 10 and later reject calls that pass different argument types to the same procedure (`Type mismatch between actual argument at (1) and actual argument at (2)`), common in legacy code that passes buffers to MPI or BLAS. Older gfortran accepts them and does not know `-fallow-argument-mismatch`. Add the flag where GCC is 10 or later: with `preferred_gcc_version=v"10"`, the libgfortran 5 variants.

```bash
if [[ "${bb_full_target}" == *libgfortran5* ]]; then
    FFLAGS="${FFLAGS} -fallow-argument-mismatch"
fi
```

## CompilerSupportLibraries_jll compat

Julia ships `CompilerSupportLibraries_jll` as a standard library, so the bound must admit the version every Julia in `julia_compat` ships: 0.3.6 in Julia 1.6, 0.5.0 in 1.7, 0.5.2 in 1.8, 1.0.2 in 1.9, 1.0.5 in 1.10, 1.1.1 in 1.11, 1.3.0 in 1.12 and 1.5.5 in 1.13. `compat="1.1.1"` needs `julia_compat="1.11"`. Raise the lower bound only when the build needs newer libraries, and raise `julia_compat` with it (see [`jll-versioning`](../jll-versioning/SKILL.md)).
