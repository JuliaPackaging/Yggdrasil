# Agent Guide for Yggdrasil Build Scripts

This guide helps AI agents generate correct `build_tarballs.jl` recipes for BinaryBuilder.jl in the Yggdrasil repository.

## Prerequisites

- **Julia**: Use the version named by `julia_version` at the top of the repo-root `Manifest.toml`, which is what CI runs.
- **Project**: Use the repo-root Project.toml.
- **Build host**: The build images (rootfs and compiler shards) are x86_64 Linux binaries, so builds need an x86_64 host. On other hosts, such as arm64 macOS, they don't work or run very slowly under emulation; let CI build instead.
- **Platforms**: `supported_platforms()` returns every target: Linux (glibc and musl), Windows, macOS and FreeBSD, on several architectures.

## Skills

Topic guidance lives in `.agents/skills/`, one `SKILL.md` per topic in the Agent Skills format. Before working on a recipe, read every skill whose condition below matches it; each is as binding as this guide.

- [`mpi-recipes`](.agents/skills/mpi-recipes/SKILL.md): the recipe depends on an MPI implementation, includes `platforms/mpi.jl` or calls `MPI.augment_platforms`, links libmpi, msmpi or mpif, or uses the `mpi` platform tag
- [`cuda-recipes`](.agents/skills/cuda-recipes/SKILL.md): the recipe uses nvcc, includes `platforms/cuda.jl` or `C/CUDA/common.jl`, depends on `CUDA_SDK_jll`, `CUDA_Runtime_jll`, `CUDA_Compiler_jll` or `CUDA_Driver_jll`, or uses the `cuda` platform tag
- [`blas-recipes`](.agents/skills/blas-recipes/SKILL.md): the recipe depends on `libblastrampoline_jll`, links `-lblastrampoline`, or calls BLAS/LAPACK with 64-bit integers (ILP64, `64_`-suffixed symbols)
- [`libjulia-recipes`](.agents/skills/libjulia-recipes/SKILL.md): the recipe depends on `libjulia_jll` or `libcxxwrap_julia_jll`, includes `L/libjulia/common.jl` or calls `libjulia_platforms`, uses the `julia_version` platform tag, or is `L/libjulia` itself
- [`jll-versioning`](.agents/skills/jll-versioning/SKILL.md): the JLL needs a version different from upstream (`ygg_version`), e.g. because a compat bound changed or a dependency moved to an ABI-breaking release, or the upstream version string is not plain `X.Y.Z`
- [`testing-jll`](.agents/skills/testing-jll/SKILL.md): every recipe, before merging: building it locally or fetching CI tarballs, and testing the generated JLL

## Essential Structure

Every `build_tarballs.jl` file follows this pattern:

```julia
using BinaryBuilder, Pkg

name = "PackageName"              # Valid Julia identifier (no spaces/dashes/dots)
version = v"X.Y.Z"                # Only major.minor.patch (no prerelease/build tags)

sources = [
    GitSource("URL", "commit_hash"; tag="v$(version)"),
    # ArchiveSource("URL", "sha256hash"),
    # DirectorySource("./bundled"),  # for patches
]

script = raw"""
cd ${WORKSPACE}/srcdir/package-*
# Build commands here
"""

platforms = supported_platforms()  # or filter as needed

products = [
    LibraryProduct("libname", :libname),
    ExecutableProduct("exename", :exename),
]

dependencies = [
    Dependency("SomeDep_jll"; compat="1.2.3"),
    # BuildDependency("BuildOnlyDep_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
```

## Critical Rules

These are the hard requirements every recipe must satisfy. The sections from
[Versions and Rebuilds](#versions-and-rebuilds) through [Testing](#testing) are rules too, as are the [Skills](#skills) that apply. Everything from
[Build Script Reference](#build-script-reference) onward is non-normative reference material.

### Naming

- **Name**: Must be a valid Julia identifier. Replace spaces/dashes with underscores. Generally match upstream casing, but use what makes most sense.
- **Version**: Only `X.Y.Z` format. Truncate any `-alpha`, `+build`, or 4+ level versions. Registration appends `+N` build numbers itself; never write one. When the JLL version or the upstream spelling differs from `version`, see [`jll-versioning`](.agents/skills/jll-versioning/SKILL.md).
- **Products**: Export symbols should match the library/executable names (as symbols: `:libname`), but use what makes sense for the package.

### Sources

- **GitSource**: For git repos. Use specific commit hash, not branch names. When building a release, also pass its `tag="v$(version)"` so reviewers see which release it is; the build checks that the tag indeed points to the hash.
- **ArchiveSource**: For tarballs (`.tar.gz`, `.tar.xz`, `.zip`). Always include SHA256 hash.
- **DirectorySource**: For local patches. Place patches in `bundled/patches/` subdirectory.
- Build **one package per recipe**. Don't bundle multiple packages—use dependencies instead.
- **GitHub archives**: Never use GitHub's generated `/archive/refs/tags/` URLs; their [checksums are not stable](https://github.blog/2023-02-21-update-on-the-future-stability-of-source-code-archives-and-hashes/). Use a `GitSource`, or a release asset the maintainers uploaded (`/releases/download/...`).
- Find a tag's commit with `git ls-remote https://github.com/owner/repo.git v1.0.0 'v1.0.0^{}'`. If this prints two lines, the tag is annotated: use the hash of the `^{}` line. The other is the tag object, not a commit, and fails the `tag` check.

### Products

- **LibraryProduct**: Shared libraries (`.so`, `.dylib`, `.dll`)
- **ExecutableProduct**: Binary executables
- **FileProduct**: Other files (headers, data files)
- **FrameworkProduct**: macOS frameworks

Every declared product must be produced on every platform it is built for: the audit fails the build if one is missing. Give product names without an extension; BinaryBuilder finds `.so`, `.dylib`, `.dll` and `.exe` itself. When a product exists only on some platforms, split the platforms and call `build_tarballs` once per group, each with its own `products` and guarded by `if any(should_build_platform.(triplet.(group_platforms)))`.

### Dependencies

- **Dependency**: Runtime dependency (will be a dependency of the generated JLL package)
- **BuildDependency**: Build-time only (not a dependency for the final JLL)
- **HostBuildDependency**: Build-time only dependency that needs to run on the build host, not target (not a dependency for the final JLL)

- Always add the `_jll` suffix.
- Every `Dependency` gets a `compat=` bound: `Dependency("Zlib_jll"; compat="1.2.13")`.
- `compat` and `julia_compat` strings are Pkg [version specifiers](https://pkgdocs.julialang.org/v1/compatibility/#Version-specifier-format), not version numbers. A bare version is a caret range up to the next breaking release: `"1.10"` and `"1.10.0"` both mean `[1.10.0, 2.0.0)`, so `julia_compat="1.10"` already admits Julia 1.11, 1.12, …, and does not pin Julia 1.10. Raising it from `"1.6"` to `"1.10"` narrows the range by dropping 1.6–1.9. Before 1.0 the range is narrower: `"0.3"` means `[0.3.0, 0.4.0)`. Other operators exist (`~`, `=`, `>=`, hyphen ranges); check their meaning at that link before using one.
- Never remove or loosen an existing bound. Entries in a compat string form a union, so `"3.0, 3.5"` still admits 3.0: raise a lower bound by replacing the entry, not by appending one.
- By default BinaryBuilder builds against the *oldest* version satisfying the bound, so raising the lower bound picks up newer artifacts. A positional pin (`Dependency("X_jll", v"1.2")` or `Dependency(PackageSpec("X_jll", v"1.2"))`) overrides the default: check for one before relying on `compat` alone, and keep it inside the bound or the build errors.
- Changing any compat bound, including `julia_compat`, requires a new JLL version; read [`jll-versioning`](.agents/skills/jll-versioning/SKILL.md) before changing `version`. Pkg cannot re-register an existing version. The exception is aligning a recipe with a fix already made in General; see [Changing compat bounds](CONTRIBUTING.md#changing-compat-bounds-of-a-package).
- Header-only or build-time-only packages are `BuildDependency`, so they are not installed on users' machines.
- Anything linking `libgfortran` needs `expand_gfortran_versions(platforms)` and `Dependency("CompilerSupportLibraries_jll")`. Don't paper over it with `preferred_gcc_version`.
- OpenMP: `CompilerSupportLibraries_jll` on non-BSD, `LLVMOpenMP_jll` on FreeBSD and macOS. Never mix headers from one with the runtime of the other.

### GCC Version Selection

Use `preferred_gcc_version=v"X"` for (see [available GCC versions](https://github.com/JuliaPackaging/Yggdrasil/blob/master/RootFS.md#compiler-shards)):

- **C++ code**: Use oldest GCC that compiles (≤10 for Julia v1.6 compatibility). Reviewers reject unexplained high versions; state the reason whenever you raise it.
- **Dependencies built with newer GCC**: Match or exceed their GCC version. Keep a library and its CxxWrap wrapper on the same GCC.
- **Musl bugs**: Use GCC ≥6 to avoid `posix_memalign` issues
- Default is GCC 4.8.5; 15.2 is the newest available.
- Clang is the opposite: latest by default. Set `preferred_llvm_version` only when required (e.g. msan).

### Style

- Prefer writing less. Every line in a recipe, script, or patch should earn its place.
- Keep comments minimal. Only comment code that is genuinely tricky (non-obvious workarounds, platform quirks, ABI hacks) and say *why*, not *what*.
- Do not comment obvious steps (`# configure`, `# build`, `# install`) or restate what the code already says.
- Comments describe the current state, never the change history. That belongs in the PR text.
- Do not assert facts about the build environment you have not verified in CI. Reviewers have caught invented justifications.
- Remove debugging residue: `ls`, `exit`, commented-out code, conditional `cd`, unused dependencies or patches.
- 4-space indentation, no tabs, one argument per line in long lists, newline at end of file.

### Patches

- Use patch files in `bundled/patches/` for source changes, never `sed`/`perl`: sed silently stops matching when upstream changes. One exception is stripping flags such as `-march` or `-ffast-math` from build files (see [Unsupported Build Flags](#unsupported-build-flags)), where a miss is harmless. The other is CRLF source files: `.gitattributes` converts patches to LF, so their context can't match. Run `dos2unix` on the file first, or use `sed` if the CRLFs must be kept.
- `DirectorySource("./bundled")` puts patches in `${WORKSPACE}/srcdir/patches/`; apply each with `atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fix.patch`.
- Each patch starts with a one-line description and a link to the upstream PR or issue. Report fixes upstream.
- Never use a personal fork or branch as a source. Keep the upstream source and carry a patch.
- Prefer a compiler flag over a patch when one suffices.

### Platforms

- Start from `supported_platforms()` and remove with `filter!`, one comment per exclusion saying what breaks. Never hand-list platforms.
- Filter by property, e.g. `nbits(p) == 64`, not by enumerating architectures.
- `expand_cxxstring_abis(platforms)` adds a variant per C++ string ABI. The audit asks for it when a library has `std::string` in its symbols.
- `Sys.isbsd(p)` also matches macOS. To target FreeBSD alone, use `Sys.isfreebsd(p)`.
- Newer macOS SDK: `include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))` then `sources, script = require_macos_sdk("11.0", sources, script)`. Never set `MACOSX_DEPLOYMENT_TARGET` by hand or edit the sysroot.
- Windows x86_64 load-time abort "32 bit pseudo relocation out of range": try `-Wl,--disable-runtime-pseudo-reloc`, else link `-static-libstdc++ -static-libgcc`.

### Shell Script Conventions

- Use `install -Dvm 755 src ${bindir}/dst` and `install_license LICENSE` instead of `cp`/`mv`. Add `-v` to `mkdir`, `cp`, `rm`.
- Never hide errors: no `|| true`, `2>/dev/null`, or `cp A || cp B`. Install declared products unconditionally; the audit fails on missing ones anyway.
- Use `${includedir}`, `${libdir}`, `${dlext}`, `${CC}`, `${CXX}`, not `${prefix}/include` or hardcoded compiler names.
- Don't set soname/install_name flags; the auditor does that. Don't set the C++ standard; upstream owns it.
- Use the upstream build system. Don't hand-invoke `${CC}` to bypass a Makefile.
- Interpolate `$(version)` into URLs and use globs like `cd package-*`; never repeat a version literal.
- The auditor requires a license under `share/licenses/<name>`. Install licenses for every bundled third-party project.

### Unsupported Build Flags

Products must not force CPU features (`-march`, `-mcpu`) unless they select code for the running processor at runtime, and must not use `-ffast-math` or `-funsafe-math-optimizations`. Strip them from the build files:

```bash
sed -i -e 's/-march[^ ]*//g' -e 's/-mcpu[^ ]*//g' -e 's/-ffast-math//g' -e 's/-funsafe-math-optimizations//g' ${files}
```

## Versions and Rebuilds

### Rebuilding Without Recipe Changes

To rebuild the same upstream version (new platform, fixed toolchain shard), bump the `# Build trigger: N` line at the end of `build_tarballs.jl`, adding it as `1` if missing. Don't add comments for this, and leave `version` alone: registration bumps the build number when the version is unchanged. The exception is a JLL old enough that a rebuild would change its `JLLWrappers` compat: General rejects build-number-only releases with different compat, so bump the patch version instead (e.g. `5.0.0` → `5.0.1`), using `ygg_version` (see [`jll-versioning`](.agents/skills/jll-versioning/SKILL.md)). Explain why in the PR.

## Special Dependencies

Some dependencies require special handling:

- **LLVM packages**: Must use `LLVM_full_jll` and match the version used by the Julia version. Requires careful ABI compatibility.
- **MPI packages**: Use `MPI.augment_platforms` from `platforms/mpi.jl`, which adds one variant per MPI ABI and the matching dependencies; read [`mpi-recipes`](.agents/skills/mpi-recipes/SKILL.md).
- **BLAS/LAPACK packages**: Should link against `libblastrampoline_jll` rather than a concrete BLAS implementation, so downstream Julia users can swap implementations at runtime; read [`blas-recipes`](.agents/skills/blas-recipes/SKILL.md).
- **CUDA packages**: Start from `H/HelloWorldCUDA`; read [`cuda-recipes`](.agents/skills/cuda-recipes/SKILL.md).
- **libjulia and CxxWrap packages**: Start CxxWrap wrappers from `H/HelloWorldCxxWrap`. Build one variant per Julia version with `libjulia_platforms` from `L/libjulia/common.jl`; read [`libjulia-recipes`](.agents/skills/libjulia-recipes/SKILL.md).

For these complex dependencies, consult existing recipes in the repository (search for `LLVM_full_jll`, `MPI.augment_platforms`, `libblastrampoline_jll`, `CUDA.required_dependencies`, or `libjulia_platforms`).

## File Organization

```text
PackageName/
├── build_tarballs.jl
└── bundled/
    └── patches/
        ├── fix1.patch
        └── fix2.patch
```

Place in alphabetical directory: `X/XYZ/build_tarballs.jl`

## Commit Messages

Format: `[PackageName] Brief description`

Examples:

- `[Zlib] Update to v1.3.1`
- `[CMake] Add OpenSSL dependency`
- `[FFMPEG] Fix build on FreeBSD`

`[skip build]` skips the build, and on merge republishes the JLL with its existing tarballs. CI reads it from the last commit of the push. Put it in the body, never in the header line.

## Pull Requests

- Work on each PR in its own git worktree, and keep the main checkout on `master`:

  ```bash
  git fetch origin master
  git worktree add --no-track -b <branch> ../<dir> origin/master
  ```

  Use a `<dir>` without slashes, e.g. `Yggdrasil-zlib`. `--no-track` keeps the branch from tracking `master`; push it with `git push -u origin <branch>`. After the PR merges, `git worktree remove --force ../<dir>` (`--force` discards untracked build output such as `products/`) and `git branch -D <branch>`.
- One recipe per PR. Never touch another recipe's files, even whitespace: any change to a `build_tarballs.jl` triggers re-registration.
- Don't edit the `.ci/bb1_project` or `.ci/bb2_project` manifests; maintainers do that with the Update Manifest workflow.
- Don't add non-recipe files (e.g. `.gitattributes`) under a recipe directory.
- CI only rebuilds a recipe when a file inside its directory changes. To rebuild the same upstream version, bump the `# Build trigger: N` line (see [Rebuilding Without Recipe Changes](#rebuilding-without-recipe-changes)).
- Don't stack PRs. A PR that depends on another's JLL cannot pass CI until that JLL is registered, so wait for the first to merge.
- Contributors cannot retry Buildkite jobs; ask a maintainer.

## Testing

Test the generated JLL before merging, so a broken package is not automatically registered in General. Read [`testing-jll`](.agents/skills/testing-jll/SKILL.md) for how.

## Build Script Reference

### Environment Variables

The script runs in an `x86_64-linux-musl` environment. Key variables:

- `${prefix}`: Install root (target for all outputs)
- `${bindir}`: Executables go here (= `${prefix}/bin`)
- `${libdir}`: Libraries go here (= `${prefix}/bin` on Windows, `${prefix}/lib` elsewhere)
- `${includedir}`: Headers go here (= `${prefix}/include`)
- `${WORKSPACE}/srcdir`: Where sources are extracted
- `${target}`: Target platform triplet; `${bb_full_target}` adds the platform tags (e.g. `cxx11`, `mpi+mpich`)
- `${MACHTYPE}`: Build host triplet
- `${nbits}`: 32 or 64
- `${dlext}`, `${exeext}`: Shared library and executable extensions (`exeext` is `.exe` on Windows, empty elsewhere)
- `${nproc}`: Number of parallel jobs
- `${CC}`, `${CXX}`, `${FC}`: Cross-compilers for C/C++/Fortran
- `${CMAKE_TARGET_TOOLCHAIN}`, `${MESON_TARGET_TOOLCHAIN}`: Toolchain files for the target
- `${rust_target}`: Rust target triplet, used in cargo output paths

Branch on `${target}` globs such as `*-mingw*`, `*-apple-*`, `*-freebsd*` and `*-musl*`, and on `${nbits}`.

### Common Build Systems

Pass the target toolchain and build with `${nproc}` jobs; otherwise use upstream's normal invocation.

- **Autotools**: `./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}`. Call `update_configure_scripts` first if `config.sub`/`config.guess` don't recognize newer platforms.
- **CMake**: `cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release`
- **Meson**: `meson setup build --cross-file="${MESON_TARGET_TOOLCHAIN}"`
- **Go**: add `compilers=[:c, :go]`, then `go build -o ${bindir}/executable${exeext}`.
- **Rust**: add `compilers=[:c, :rust]` (toolchain 1.97 supports riscv64 and FreeBSD aarch64), then `cargo build --release` and `install -Dvm 755 target/${rust_target}/release/executable${exeext} -t ${bindir}`.

### Optional Arguments to `build_tarballs`

```julia
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.10",                   # Julia [1.10, 2.0); see Dependencies
    preferred_gcc_version=v"8",            # GCC version
    preferred_llvm_version=v"13",          # LLVM version
    compilers=[:c, :rust],                 # Additional compilers
    clang_use_lld=false,                   # Opt out of LLD when clang links
    dont_dlopen=true,                      # Skip dlopen during the build audit only; the JLL still loads at init
    skip_audit=true,                       # Last resort; say why in the PR
    init_block="...",                      # Julia code run at JLL __init__
)
```

`RuntimeDependency` declares a JLL needed at runtime but not at build time.

To stop the JLL itself from dlopening a library at init (GPU libs, plugins), set it on the product: `LibraryProduct("libfoo", :libfoo; dont_dlopen=true)`.

Note: `julia_compat` is the **JLL's** Julia compat bound, independent of the Julia
version required to *run* BinaryBuilder.jl itself (see [Prerequisites](#prerequisites)).

## Common Patterns

### Multi-Variant Recipes

Put shared logic in `PackageName/common.jl` and one `build_tarballs.jl` per variant in subdirectories (`PackageName/PackageName`, `PackageName/PackageName32`). Keep an old version alongside a new one in a `PackageName@<version>/` directory, with as many version components as needed to tell them apart (`PackageName@1.5`, `PackageName@18`).

### Platform Augmentation Helpers

`platforms/` also provides `llvm.jl` (`LLVM.augment`, `LLVM.platform`, adds an `llvm_version` tag) and `microarchitectures.jl` (`MicroArchitectures.augment`, `expand_microarchitectures`). Follow an existing consumer.

## Troubleshooting

**Can't find headers/libraries**: `export CPPFLAGS="-I${includedir}" LDFLAGS="-L${libdir}"`.

**Old `config.sub`/`config.guess`**: call `update_configure_scripts` (see [Common Build Systems](#common-build-systems)).

**Foreign executable error**: Can't run cross-compiled executables. Patch build system or build tools natively.

**Link errors about unrecognized relocations**: Increase `preferred_gcc_version` to match dependencies

## Reference Examples

The `H/HelloWorld*` recipes show the toolchain setup for each language and special dependency: `HelloWorldC` (C, CMake), `HelloWorldCxx`, `HelloWorldFortran`, `HelloWorldGo`, `HelloWorldRust`, `HelloWorldMPIC`, `HelloWorldMPIFortran`, `HelloWorldCUDA` and `HelloWorldCxxWrap`. They build small test programs instead of an upstream release, so take sources, patches and build system usage from this guide, not from them.

## MCP Tooling

`.agents/mcp-bb-sandbox/` holds `bb-sandbox`, an MCP server that drives an interactive BinaryBuilder cross-compilation sandbox. Its [README](.agents/mcp-bb-sandbox/README.md) explains how to register and set it up.

## Additional Resources

- [BinaryBuilder Documentation](https://docs.binarybuilder.org)
- [Build Tips](https://docs.binarybuilder.org/stable/build_tips/)
- [Troubleshooting](https://docs.binarybuilder.org/stable/troubleshooting/)
- [CONTRIBUTING.md](CONTRIBUTING.md) in this repository
- [RootFS.md](RootFS.md) for compiler versions and cross-compilation details
