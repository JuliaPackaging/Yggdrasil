---
name: libjulia-recipes
description: Rules for Yggdrasil recipes built against Julia's headers, including CxxWrap wrappers. Use when a build_tarballs.jl depends on libjulia_jll or libcxxwrap_julia_jll, includes L/libjulia/common.jl or calls libjulia_platforms, uses the julia_version platform tag, or when updating L/libjulia itself.
---

# libjulia and CxxWrap packages

Anything built against Julia's headers, such as [CxxWrap.jl](https://github.com/JuliaInterop/CxxWrap.jl) wrappers, GAP or jlrs-based crates, is tied to a Julia minor version. `libjulia_platforms(v)` tags each platform with `julia_version=v`. Julia's host platform carries the same tag and matches it on major.minor, so no augmentation block is needed.

For a CxxWrap wrapper, start from `H/HelloWorldCxxWrap`:

```julia
include("../../L/libjulia/common.jl")  # also loads macos_sdks.jl
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

dependencies = [
    BuildDependency(PackageSpec(; name="libjulia_jll", version="1.11.4")),
    Dependency("libcxxwrap_julia_jll"; compat="0.14.12"),
]

@assert libjulia_min_julia_version <= v"1.10.0"

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat=libjulia_julia_compat(julia_versions),
    preferred_gcc_version=v"8")
```

- **`libjulia_jll`** is always a `BuildDependency`: the running Julia supplies `libjulia`. Pin it to `jllversion` from `L/libjulia/build_tarballs.jl`. Older releases lack artifacts for newer Julia versions; the history comment in `common.jl` lists the first release for each.
- **`julia_compat`**: use `libjulia_julia_compat(julia_versions)`, which yields `~1.10, ~1.11, …` and admits only Julia versions that have an artifact. A plain `"1.10"` admits future Julia versions the JLL was not built for.
- **Julia versions**: `julia_versions` comes from `common.jl` with prerelease tags stripped, so `1.15.0-DEV` appears as `v"1.15.0"`. To drop some, filter it right after the include, before computing platforms and `julia_compat`, e.g. `filter!(>=(v"1.11"), julia_versions)`. Filter platforms after `libjulia_platforms`, then call `expand_cxxstring_abis`.
- **Versioning**: when `common.jl` adds or drops a Julia version that the recipe's filter keeps (any version, for a recipe that is unfiltered or filtered only by a lower bound), its `julia_compat` changes on its next build. That rebuild needs a new JLL version, not a `# Build trigger` bump (see [Dependencies](../../../AGENTS.md#dependencies)). Without a new upstream release, keep `version` and raise `ygg_version` (see [`jll-versioning`](../jll-versioning/SKILL.md)). `@assert libjulia_min_julia_version <= v"1.10.0"` makes dropping the oldest Julia version fail the build instead of silently narrowing `julia_compat`.
- **Local builds**: the triplet carries the tag, e.g. `x86_64-linux-gnu-cxx11-julia_version+1.12.0`.

## CxxWrap

- **CMake**: projects using `find_package(JlCxx)` need `-DJulia_PREFIX=${prefix}` and `-DCMAKE_FIND_ROOT_PATH=${prefix}` on top of the usual CMake flags.
- **`libcxxwrap_julia_jll` compat**: before 1.0, each minor release (0.13 → 0.14) breaks ABI. Admit exactly one minor, and one that the Julia package's CxxWrap.jl accepts, per the `libcxxwrap_julia_jll` entry in CxxWrap.jl's `Project.toml`. BinaryBuilder builds against the oldest version in the bound, so the lower bound must be a release built for every Julia version in `julia_versions`.
- **GCC**: the `JlCxx::cxxwrap_julia` CMake target requires C++20, which CMake supports from GCC 8; use the oldest GCC from 8 up that compiles the wrapper (see [GCC Version Selection](../../../AGENTS.md#gcc-version-selection)).
- `L/libcxxwrap_julia` builds CxxWrap itself; it is not a template for a wrapper.

## Julia updates

**ABI change in an unreleased Julia.** When Julia master or a release branch before its release breaks ABI, `L/libjulia` moves that version's `-DEV` commit and bumps `jllversion`. `julia_compat` is unchanged, so dependents need no new JLL version: once CI against that Julia version reports errors, raise the `libjulia_jll` pin, which rebuilds the recipe.

**New Julia version.** This takes up to three PRs, each after the previous JLL is registered:

1. `L/libjulia`, in `common.jl`:
    - add the version to `julia_full_versions`, with a `checksums` entry, or a `GitSource` branch for `-DEV`;
    - in the `build_julia` bash script, add an `LLVMVERMAJOR`/`LLVMVERMINOR` branch and widen version globs such as the mingw `1.1[3-5].*`. These match `${version}`, the content of Julia's `VERSION` file (e.g. `1.15.0-DEV`), not the JLL version;
    - add a `version.minor` branch for its `LLVM_full_jll` and other build dependencies;
    - update the history comment.

    Put any patches in `bundled/patches/<VERSION>/` and bump `jllversion` in `build_tarballs.jl`.
2. `L/libcxxwrap_julia`: raise the `libjulia_jll` pin and give the JLL a new version (see Versioning above).
3. Each consumer: the same, and for a CxxWrap wrapper raise the `libcxxwrap_julia_jll` lower bound. Consumers that don't use CxxWrap, such as GAP or jlrs-based recipes, don't wait for step 2.
