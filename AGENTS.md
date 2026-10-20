# Agent Guide for Yggdrasil Build Scripts

This guide helps AI agents generate correct `build_tarballs.jl` recipes for BinaryBuilder.jl in the Yggdrasil repository.

## Prerequisites

- **Julia**: Use the version named by `julia_version` at the top of the repo-root `Manifest.toml`, which is what CI runs.
- **Project**: Use the repo-root Project.toml.
- **Supported Platforms**: Linux glibc (x86_64, i686, aarch64, armv7l, armv6l, ppc64le, riscv64), Linux musl (x86_64, i686, aarch64, armv7l, armv6l), Windows (x86_64, i686), macOS (x86_64, aarch64), FreeBSD (x86_64, aarch64)
- Use `supported_platforms()` to get all available platforms

## Essential Structure

Every `build_tarballs.jl` file follows this pattern:

```julia
using BinaryBuilder, Pkg

name = "PackageName"              # Valid Julia identifier (no spaces/dashes/dots)
version = v"X.Y.Z"                # Only major.minor.patch (no prerelease/build tags)

sources = [
    ArchiveSource("URL", "sha256hash"),
    # GitSource("URL", "commit_hash"),
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

These are the hard requirements every recipe must satisfy. Special Dependencies,
File Organization, Commit Messages, Pull Requests and Testing are rules too. Everything from
[Build Script Reference](#build-script-reference) onward is non-normative reference material.

### Naming

- **Name**: Must be a valid Julia identifier. Replace spaces/dashes with underscores. Generally match upstream casing, but use what makes most sense.
- **Version**: Only `X.Y.Z` format. Truncate any `-alpha`, `+build`, or 4+ level versions. Yggdrasil itself uses `+N` to rebuild the same upstream version. When the JLL version or the upstream spelling differs from `version`, see [Upstream and JLL Versions](#upstream-and-jll-versions).
- **Products**: Export symbols should match the library/executable names (as symbols: `:libname`), but use what makes sense for the package.

### Sources

- **ArchiveSource**: For tarballs (`.tar.gz`, `.tar.xz`, `.zip`). Always include SHA256 hash.
- **GitSource**: For git repos. Use specific commit hash, not branch names. When building a release, also pass its `tag="v$(version)"` so reviewers see which release it is; the build checks that the tag indeed points to the hash.
- **DirectorySource**: For local patches. Place patches in `bundled/patches/` subdirectory.
- Build **one package per recipe**. Don't bundle multiple packages—use dependencies instead.

#### GitHub Archive Sources

**IMPORTANT**: GitHub's automatically generated archive sources (`/archive/refs/tags/` URLs) do **not** have stable checksums and cannot be used. See [GitHub's announcement](https://github.blog/2023-02-21-update-on-the-future-stability-of-source-code-archives-and-hashes/).

Instead:

1. **Use GitSource with commit hash** (preferred):

   ```julia
   sources = [
       GitSource("https://github.com/owner/repo.git", "full_commit_hash"; tag="v$(version)"),
   ]
   ```

2. **Use official release assets**: If maintainers upload release tarballs (not auto-generated):

   ```julia
   sources = [
       ArchiveSource("https://github.com/owner/repo/releases/download/v1.0.0/package-1.0.0.tar.gz", "sha256"),
   ]
   ```

To find the commit hash for a tag:

```bash
git ls-remote https://github.com/owner/repo.git v1.0.0 'v1.0.0^{}'
```

If this prints two lines, the tag is annotated: use the hash of the `^{}` line. The other is the tag object, not a commit, and fails the `tag` check.

### Products

- **LibraryProduct**: Shared libraries (`.so`, `.dylib`, `.dll`)
- **ExecutableProduct**: Binary executables
- **FileProduct**: Other files (headers, data files)
- **FrameworkProduct**: macOS frameworks

Every declared product must actually be produced by the build on every supported platform — BinaryBuilder audits the install prefix after the script runs and fails the build if any listed product is missing. Gate platform-specific products with `Platform`-aware filters (e.g. only declare a `.dll` on Windows) rather than listing them unconditionally.

### Dependencies

- **Dependency**: Runtime dependency (will be a dependency of the generated JLL package)
- **BuildDependency**: Build-time only (not a dependency for the final JLL)
- **HostBuildDependency**: Build-time only dependency that needs to run on the build host, not target (not a dependency for the final JLL)

- Always add the `_jll` suffix.
- Every `Dependency` gets a `compat=` bound: `Dependency("Zlib_jll"; compat="1.2.13")`.
- Never remove or loosen an existing bound. Compat strings are set unions, so `"3.0, 3.5"` means the same as `"3.0"`.
- By default BinaryBuilder builds against the *oldest* version satisfying the bound, so raising the lower bound picks up newer artifacts. A positional pin (`Dependency("X_jll", v"1.2")` or `Dependency(PackageSpec("X_jll", v"1.2"))`) overrides the default: check for one before relying on `compat` alone, and keep it inside the bound or the build errors.
- Changing any compat bound, including `julia_compat`, requires bumping the JLL version. Pkg cannot re-register an existing version.
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

- Use patch files in `bundled/patches/` for source changes, never `sed`/`perl`: sed silently stops matching when upstream changes. The one exception is stripping flags such as `-march` or `-ffast-math` from build files (see [Unsupported Build Flags](#unsupported-build-flags)), where a miss is harmless.
- Each patch starts with a one-line description and a link to the upstream PR or issue. Report fixes upstream.
- Never use a personal fork or branch as a source. Keep the upstream source and carry a patch.
- Prefer a compiler flag over a patch when one suffices.

### Platforms

- Start from `supported_platforms()` and remove with `filter!`, one comment per exclusion saying what breaks. Never hand-list platforms.
- Filter by property, e.g. `nbits(p) == 64`, not by enumerating architectures.
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

Products should not force using certain CPUs or instruction sets (e.g., the `march` or `mcpu` flags), unless they perform their own selection of the appropriate code for the current processor at runtime.
They also should not use unsafe math operations or fast-math mode in compilers.

To remove the `march` and `mcpu` flags in a list of files:

```bash
for i in ${files}; do
    sed -i "s/-march[^ ]*//g" $i
    sed -i "s/-mcpu[^ ]*//g" $i
done
```

To remove the fast math and unsafe math optimizations in a list of files:

```bash
for i in ${files}; do
    sed -i "s/-ffast-math//g" $i
    sed -i "s/-funsafe-math-optimizations//g" $i
done
```

## Special Dependencies

Some dependencies require special handling:

- **LLVM packages**: Must use `LLVM_full_jll` and match the version used by the Julia version. Requires careful ABI compatibility.
- **MPI packages**: Use `MPI.augment_platforms` from `platforms/mpi.jl`, which adds one variant per MPI ABI and the matching dependencies; see [MPI packages](#mpi-packages).
- **BLAS/LAPACK packages**: Should link against `libblastrampoline_jll` rather than a concrete BLAS implementation, so downstream Julia users can swap implementations at runtime.
- **CUDA packages**: Use `CUDA.required_dependencies` to get the necessary runtime dependencies. Must handle different CUDA versions. GPU code needs special compilation flags.

For these complex dependencies, consult existing recipes in the repository (search for `LLVM_full_jll`, `MPI.augment_platforms`, `libblastrampoline_jll`, or `CUDA.required_dependencies`).

### MPI packages

MPI recipes use a platform-tag augmentation scheme so a single set of JLLs can be retargeted at runtime via `MPIPreferences.jl`. Five ABIs are supported (`MPIABI`, `MPICH`, `MPItrampoline`, `OpenMPI`, `MicrosoftMPI`); the orchestration lives in `platforms/mpi.jl`.

Standard recipe shape (see `H/HYPRE/common.jl`, `P/PETSc/build_tarballs.jl`, `S/SCALAPACK/common.jl`):

```julia
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
# ...
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)   # if Fortran code
platforms, platform_dependencies = MPI.augment_platforms(platforms)
augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""
append!(dependencies, platform_dependencies)
build_tarballs(...; augment_platform_block, ...)
```

`MPI.augment_platforms` expands each base platform into one variant per allowed ABI, adds an `mpi=<abi>` tag, and returns the matching `Dependency` list (including `MPIPreferences`). Its default compat bounds are good; only pass `MPICH_compat=` etc. when a package genuinely needs it.

Recurring gotchas:

- **MPItrampoline** does not support musl or Windows; **OpenMPI** is unavailable on `armv6l-linux-gnu`. The `mpi_abis` table in `platforms/mpi.jl` already encodes this; don't re-filter in the recipe.
- **Fortran-bearing libraries** must call `expand_gfortran_versions(platforms)` *before* `MPI.augment_platforms`; C++-heavy packages often also need `expand_cxxstring_abis`.
- **Per-ABI linking** is selected with `if [[ ${bb_full_target} == *mpiabi* ]]; then …` blocks; each ABI exposes a different set of libraries (`libmpitrampoline`, `libmpi`+`libmpifort`, `libmpi`+`libmpi_mpifh`+`libmpi_usempif08`, `msmpi64`). `P/PETSc/build_tarballs.jl` is the canonical reference.
- **Windows (MicrosoftMPI)** needs `-DMPI_HOME=${prefix} -DMPI_GUESS_LIBRARY_NAME=MSMPI` and `-DMPI_${lang}_LIBRARIES=msmpi64` for CMake; see `H/HYPRE/common.jl`.
- MPI-flavored dependencies must use the same compat (including the exact OpenMPI pin) as the JLL they were built against.

### CUDA packages

CUDA tooling and platform augmentation live in `platforms/cuda.jl` (with the underlying JLLs under `C/CUDA/`). Depend on the right combination via `CUDA.required_dependencies(platform)` rather than naming the JLLs directly:

- `CUDA_SDK_jll` / `CUDA_SDK_static_jll` — full toolkit (headers + libs), build-only (`BuildDependency`).
- `CUDA_Runtime_jll` — slim redistributable runtime libs (cudart, cublas, cufft, curand, cusolver, cusparse, nvrtc, nvjitlink); the user-facing artifact.
- `CUDA_Driver_jll` — wraps the system driver and provides `inspect_driver` for compute-capability detection during platform augmentation.

Standard recipe shape (see `A/AMGX/build_tarballs.jl`, `H/HeFFTe/build_tarballs.jl`):

```julia
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
platforms = CUDA.supported_platforms()           # one platform per CUDA minor version
filter!(p -> arch(p) == "x86_64", platforms)     # optional

for platform in platforms
    should_build_platform(triplet(platform)) || continue
    dependencies = CUDA.required_dependencies(platform; static_sdk=true)
    build_tarballs(ARGS, name, version, sources, script, [platform],
                   products, dependencies; lazy_artifacts=true,
                   augment_platform_block=CUDA.augment,
                   dont_dlopen=true, preferred_gcc_version=v"9")
end
```

Concrete rules:

- **Platforms:** Linux `x86_64-glibc` and `aarch64-glibc` only (aarch64 split into `cuda_platform=jetson` vs `sbsa` for CUDA <13). Windows, musl, and macOS are unsupported.
- **Supported toolkit versions** are listed in `CUDA.cuda_full_versions` in `platforms/cuda.jl`; pre-release toolkits need `CUDA.supported_platforms(; prereleases=true)`. Build one variant per CUDA minor; the `cuda=$MAJOR.$MINOR` platform tag drives selection.
- **Select platforms by exact triplet** in multi-variant loops. `platforms_match` treats a missing `cuda` tag as a wildcard and will serialise every variant into one job.
- **`CUDA.augment` block is required** on consumers — it reads `CUDA_Runtime_jll` `Preferences` (`version`, `local`), detects driver capabilities via `CUDA_Driver_jll.inspect_driver`, and picks the highest-compatible toolkit. Consumers of the JIT stack use `CUDA.compiler_augment` instead. Compute-capability support is encoded in `cuda_cap_db` in `C/CUDA/CUDA_Runtime/toolkit_selection.jl`.
- Use `CUDA.cuda_gpu_archs(platform)` for `-DCMAKE_CUDA_ARCHITECTURES` (see `A/AMGX`).
- **Build flags:** point CMake at the bundled toolkit with `-DCMAKE_CUDA_COMPILER=$prefix/cuda/bin/nvcc -DCMAKE_CUDA_FLAGS="-L${prefix}/cuda/lib"`. `nvcc` writes scratch to `/tmp` (small tmpfs in the sandbox); redirect with `export TMPDIR=${WORKSPACE}/tmpdir`.
- Pass **`static_sdk=true`** to `required_dependencies` when linking static CUDA libs (e.g. AMGX); this adds `CUDA_SDK_static_jll` as a `BuildDependency`.
- Always pass **`dont_dlopen=true`** and **`lazy_artifacts=true`** to `build_tarballs` for CUDA consumers — the sandbox has no driver, so the audit cannot dlopen the libraries. This does not stop the JLL from loading them at init; use `LibraryProduct(...; dont_dlopen=true)` for that.
- **NVIDIA redistributable archive** SHAs are published per CUDA release in `redistrib_<version>.json`; `cuda_nvcc_redist_source` / `get_sources` in `platforms/cuda.jl` and `C/CUDA/common.jl` handle this — prefer them over hand-rolled `ArchiveSource` URLs.

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

`[skip build]` republishes the JLL without rebuilding (metadata-only changes such as compat bounds). Put it in the body of every commit in the push, never in the header line.

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

Test the generated JLL locally before merging, so a broken package is not automatically registered in General.

### Build and Generate the JLL

```bash
cd X/PackageName
julia --project build_tarballs.jl --verbose --deploy=local x86_64-linux-gnu
```

This puts tarballs in `products/` and writes a local JLL package to `~/.julia/dev/PackageName_jll/`. The trailing triplet builds only that platform; omit it to build all of them. Use it for local testing only, never narrow `platforms` in the recipe to match. While iterating on a failing build, add `--debug` to drop into the sandbox shell on failure. On macOS, local builds need Docker.

### Test the JLL Package

Create a test script to verify the JLL works:

```julia
using Pkg

# Add the local JLL package
Pkg.develop(path=expanduser("~/.julia/dev/PackageName_jll"))

# Now test it
using PackageName_jll

# Test that products are accessible
@info "Package path:" PackageName_jll.artifact_dir

# JLLs export each ExecutableProduct as a function named after its symbol.
# E.g. for `ExecutableProduct("zstd", :zstd)` the wrapper is `Zstd_jll.zstd()`,
# which returns a Cmd usable with `run` or string interpolation.
# Replace `executable_name` below with your actual product symbol.
@info "Executable Cmd:" PackageName_jll.executable_name()

# Try running the executable (if applicable)
run(`$(PackageName_jll.executable_name()) --version`)
```

### Test with Dependencies

If your package will be used by other Julia packages, test the integration:

```julia
# Create a temporary test environment
using Pkg
Pkg.activate(mktempdir())

# Add your local JLL
Pkg.develop(path=expanduser("~/.julia/dev/PackageName_jll"))

# Add a package that should use your JLL
Pkg.add("SomePackageThatUsesYourJLL")

# Test that it works
using SomePackageThatUsesYourJLL
# ... run tests ...
```

### Clean Up Before Pushing

After testing, clean up the local build artifacts:

```bash
# Remove generated products
rm -rfv products/

# Remove the local JLL dev package (optional)
rm -rfv ~/.julia/dev/PackageName_jll/
```

### Alternative: Use CI Artifacts

For complex packages, you can also:

1. Push your branch to GitHub
2. Wait for the Buildkite build jobs to finish
3. Download the `products/*` tarballs from each job's Artifacts tab
4. Test the prebuilt binaries locally

### What to Test

- [ ] All products are accessible and have correct paths
- [ ] Executables run without errors (at minimum `--version` or `--help`)
- [ ] Libraries can be loaded (`dlopen` doesn't fail)
- [ ] Dependencies are correctly linked
- [ ] Platform-specific behavior works (if applicable)
- [ ] Package imports without warnings or errors

## Build Script Reference

Reference material for writing the `script` block — environment variables, common
build-system invocations, platform branching, and optional `build_tarballs` keyword
arguments.

### Environment Variables

The script runs in an `x86_64-linux-musl` environment. Key variables:

- `${prefix}`: Install root (target for all outputs)
- `${bindir}`: Executables go here (= `${prefix}/bin`)
- `${libdir}`: Libraries go here (= `${prefix}/bin` on Windows, `${prefix}/lib` elsewhere)
- `${includedir}`: Headers go here (= `${prefix}/include`)
- `${WORKSPACE}/srcdir`: Where sources are extracted
- `${target}`: Target platform triplet
- `${nproc}`: Number of parallel jobs
- `${CC}`, `${CXX}`, `${FC}`: Cross-compilers for C/C++/Fortran

### Common Build Systems

**Autotools**:

```bash
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
```

Call `update_configure_scripts` before `./configure` if the package's `config.sub`/`config.guess` files don't recognize newer platforms.

**CMake**:

```bash
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
```

**Meson**:

```bash
meson setup build --cross-file="${MESON_TARGET_TOOLCHAIN}"
meson compile -C build -j${nproc}
meson install -C build
```

**Make**:

```bash
make -j${nproc} PREFIX=${prefix}
make install PREFIX=${prefix}
```

**Go** (add `compilers=[:c, :go]`):

```bash
go build -o ${bindir}/executable
```

**Rust** (add `compilers=[:c, :rust]`; toolchain 1.97 supports riscv64 and FreeBSD aarch64):

```bash
cargo build --release
install -Dvm755 target/*/release/executable ${bindir}/executable
```

### Platform-Specific Logic

```bash
if [[ "${target}" == *-mingw* ]]; then
    # Windows-specific
elif [[ "${target}" == *-apple-* ]]; then
    # macOS-specific
elif [[ "${target}" == *-freebsd* ]]; then
    # FreeBSD-specific
fi

if [[ ${nbits} == 32 ]]; then
    # 32-bit specific
fi
```

### Optional Arguments to `build_tarballs`

```julia
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.10",                   # Minimum Julia version for the JLL
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

### Applying Patches

```julia
sources = [
    ArchiveSource("..."),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/package-*
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fix.patch
# ... rest of build
"""
```

### Platform Filtering

```julia
platforms = supported_platforms()
# Upstream assumes 64-bit pointers
filter!(p -> nbits(p) == 64, platforms)

# Expand C++ string ABI variants
platforms = expand_cxxstring_abis(platforms)

# Expand Fortran library versions (only for Fortran codes)
platforms = expand_gfortran_versions(platforms)
```

### Setting Environment Variables

```bash
export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"
export PKG_CONFIG_PATH="${prefix}/lib/pkgconfig:${PKG_CONFIG_PATH}"
```

### Multi-Variant Recipes

Put shared logic in `PackageName/common.jl` and one `build_tarballs.jl` per variant in subdirectories (`S/SCALAPACK/{SCALAPACK,SCALAPACK32,SCALAPACK64}`). Keep an old version alongside a new one in a `PackageName@<version>/` directory, with as many version components as needed to tell them apart (`T/TetGen/TetGen@1.5`, `L/LLVM/Clang@18`).

### Platform Augmentation Helpers

`platforms/` also provides `llvm.jl` (`LLVM.augment`, `LLVM.platform`, adds an `llvm_version` tag) and `microarchitectures.jl` (`MicroArchitectures.augment`, `expand_microarchitectures`). Follow an existing consumer.

### Rebuilding Without Recipe Changes

To rebuild the same upstream version (new platform, fixed toolchain shard), bump the `# Build trigger: N` line at the end of `build_tarballs.jl`, adding it as `1` if missing. Don't add comments for this, and leave `version` alone: a build number cannot be set by hand, registration bumps it automatically when the version is unchanged. The exception is a JLL old enough that a rebuild would change its `JLLWrappers` compat: General rejects build-number-only releases with different compat, so bump the patch version instead (GLPK 5.0 → 5.0.1), using `ygg_version` (see below). Explain why in the PR.

### Upstream and JLL Versions

`version` names the upstream release: URLs, tags, and versioned library names derive from it. When the JLL needs a different version, keep `version` and add `ygg_version`, which is what `build_tarballs` gets:

```julia
version = v"1.6.0"
ygg_version = v"1.6.1"  # Rebuilt against Giflib_jll 6

build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies)
```

Use this when:

- A rebuild must get a new JLL version rather than a new build number, e.g. because a compat bound changed (see [Dependencies](#dependencies)) or a dependency moved to a new ABI-breaking release. Say why in a comment.
- Upstream does not use semantic versioning, e.g. `D/DecFP` maps upstream `20U4` to `ygg_version = v"2.0.400"`.

Every new `ygg_version` must exceed all registered versions of the JLL, and downstream compat bounds refer to `ygg_version`, not to upstream. Bumping the patch (`1.6.0` → `1.6.1`) collides with upstream's next patch release: when upstream releases `1.6.1`, the JLL needs `ygg_version = v"1.6.2"`. Drop `ygg_version` once `version` is larger than every registered JLL version again. Recipes that rebuild often reserve room instead (`S/SCALAPACK`, `G/Gnuplot`):

```julia
version = v"2.2.3"
offset = 1  # bump for rebuilds, reset on a new upstream release
ygg_version = VersionNumber(version.major, version.minor, 100 * version.patch + offset)
```

Keep whatever scheme the recipe already uses; switching back would make the JLL version go down.

When the upstream spelling of a version can't be recovered from a `VersionNumber` (e.g. `"2.8"` prints as `2.8.0`), keep the upstream string and derive `version` from it, so the version literal appears only once:

```julia
version_string = "2.8"
version = VersionNumber(version_string)

sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/gsl/gsl-$(version_string).tar.gz", "sha256"),
]
```

Interpolate `version_string` into URLs, tags, and directory names, and `version` everywhere a `VersionNumber` is needed. Existing recipes call it `version_string` or `version_str`; follow the recipe at hand. The two mechanisms combine, e.g. `G/GSL/GSL@2` has `version_string = "2.8"` and `ygg_version = v"2.8.1"`. Upstream versions with four or more components (`"2.1.12.5"`) do not parse as a `VersionNumber`, so set `version` by hand instead.

## Troubleshooting

### Build Failures

**Can't find headers/libraries**: set the flags in [Setting Environment Variables](#setting-environment-variables).

**Old `config.sub`/`config.guess`**: call `update_configure_scripts` (see [Common Build Systems](#common-build-systems)).

**Foreign executable error**: Can't run cross-compiled executables. Patch build system or build tools natively.

**Missing shared library on PowerPC**: Regenerate configure: `autoreconf -vi` before `./configure`

**Link errors about unrecognized relocations**: Increase `preferred_gcc_version` to match dependencies

### JLL Testing

**JLL not found after `Pkg.develop`**:

- Make sure the path is correct: `~/.julia/dev/PackageName_jll/`
- Try `Pkg.resolve()` to refresh the manifest

**Products not working**:

- Check that products in `build_tarballs.jl` match actual files
- Verify executables are actually executable: `ls -la`
- On macOS, check for quarantine flags: `xattr -d com.apple.quarantine file`

**Dependency conflicts**:

- Use a fresh Julia environment for testing
- Check that dependencies have correct compat bounds

## Reference Examples

- **Autotools with patches**: `S/sshpass/build_tarballs.jl` (`bundled/patches/`)
- **Meson with patches**: `Z/Zstd/build_tarballs.jl` (`bundled/patches/`)
- **CMake with dependencies**: `C/CMake/build_tarballs.jl`
- **Platform-specific builds**: `G/Git/build_tarballs.jl`
- **Multiple sources**: `L/libftd2xx/build_tarballs.jl`

## MCP Tooling

This repo ships an MCP server for AI coding agents, configured in `.mcp.json`:

- **`bb-sandbox`** (`.claude/mcp-bb-sandbox/server.jl`) — launches and drives an
  interactive BinaryBuilder cross-compilation sandbox. Tools: `sandbox_start`,
  `sandbox_exec`, `sandbox_stop`, `sandbox_list`, `sandbox_str_replace_editor`.

The server runs from the `.claude/` Julia environment and shells out to the
repo-root project of the checkout it lives in for `build_tarballs.jl --debug`.
The server and its subprocesses run on the `julia` found on `PATH`, so it must
be the version from [Prerequisites](#prerequisites).
`.claude/Manifest.toml` is not checked in, so it resolves against the latest
`[sources]` branches. On a fresh checkout or worktree instantiate both once,
otherwise `bb-sandbox` fails to connect with a missing-package error (e.g.
`ClaudeMCPTools`). From the checkout root:

```bash
julia --project=.claude -e 'using Pkg; Pkg.instantiate()'
julia --project -e 'using Pkg; Pkg.instantiate()'
```

After that, the agent's MCP status should show `bb-sandbox` connected.

`sandbox_start` takes an absolute `build_tarballs_path`, so a server started in
the main checkout can build a recipe in any worktree. The recipe then runs
against the main checkout's root project, so keep that checkout's `master` up to
date with `git pull`. To use the worktree's own project instead, start the agent
from the worktree so it launches that worktree's server.

## Additional Resources

- [BinaryBuilder Documentation](https://docs.binarybuilder.org)
- [Build Tips](https://docs.binarybuilder.org/stable/build_tips/)
- [Troubleshooting](https://docs.binarybuilder.org/stable/troubleshooting/)
- [CONTRIBUTING.md](CONTRIBUTING.md) in this repository
- [RootFS.md](RootFS.md) for compiler versions and cross-compilation details
