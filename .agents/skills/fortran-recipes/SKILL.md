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
| 3 | 4.8 to 6 |
| 4 | 7 |
| 5 | 8 and later |

`preferred_gcc_version` selects the closest GCC within a variant's series, so `preferred_gcc_version=v"10"` still builds the libgfortran 3 variants with GCC 6 and the libgfortran 4 variants with GCC 7, without warning. Code that needs a newer compiler fails only on those variants. Drop them after expanding, saying what fails:

```julia
platforms = expand_gfortran_versions(supported_platforms())
# Needs C++17
filter!(p -> libgfortran_version(p) >= v"5", platforms)
```

## Argument mismatch

gfortran 10 and later reject calls that pass different argument types to the same procedure (`Type mismatch between actual argument at (1) and actual argument at (2)`), common in legacy code that passes buffers to MPI or BLAS. Older gfortran accepts them and does not know `-fallow-argument-mismatch`, so add the flag only where the compiler is 10 or later:

```bash
if (( $(${FC} -dumpversion | cut -d. -f1) >= 10 )); then
    FFLAGS="${FFLAGS} -fallow-argument-mismatch"
fi
```

## CompilerSupportLibraries_jll compat

Julia ships `CompilerSupportLibraries_jll` as a standard library, so the bound must admit the version every Julia in `julia_compat` ships, which `stdlib/CompilerSupportLibraries_jll/Project.toml` at that Julia's release tag records. In practice the lower bound must not exceed what the oldest Julia in `julia_compat` ships. Raise the lower bound only when the build needs newer libraries, and raise `julia_compat` with it (see [`jll-versioning`](../jll-versioning/SKILL.md)).
