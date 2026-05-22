# Agent Guide for Yggdrasil Build Scripts

This guide helps AI agents generate correct `build_tarballs.jl` recipes for BinaryBuilder.jl in the Yggdrasil repository.

## Prerequisites

- **BinaryBuilder.jl**: Requires at least Julia 1.12.
- **Supported Platforms**: Linux (glibc and musl for x86_64, i686, aarch64, armv7l, armv6l, ppc64le, riscv64), Windows (x86_64, i686), macOS (x86_64, aarch64), FreeBSD (x86_64, aarch64)
- Use `supported_platforms()` to get all available platforms

## Special Dependencies

Some dependencies require special handling:

- **LLVM packages**: Must use `LLVM_full_jll` and match the version used by the Julia version. Requires careful ABI compatibility.
- **MPI packages**: Need `MPIPreferences.jl` configuration and must use `MPItrampoline_jll` for cross-implementation compatibility.
- **BLAS/LAPACK packages**: Should link against `libblastrampoline_jll` rather than a concrete BLAS implementation, so downstream Julia users can swap implementations at runtime.
- **CUDA packages**: Use `CUDA.required_dependencies` to get the necessary runtime dependencies. Must handle different CUDA versions. GPU code needs special compilation flags.

For these complex dependencies, consult existing recipes in the repository (search for `LLVM_full_jll`, `MPItrampoline_jll`, `libblastrampoline_jll`, or `CUDA.required_dependencies`).

### MPI packages

MPI recipes use a platform-tag augmentation scheme so a single set of JLLs can be retargeted at runtime via `MPIPreferences.jl`. Five ABIs are supported (`MPIABI`, `MPICH`, `MPItrampoline`, `OpenMPI`, `MicrosoftMPI`); the orchestration lives in `platforms/mpi.jl`.

Standard recipe shape (see `H/HYPRE/build_tarballs.jl`, `P/PETSc/build_tarballs.jl`, `S/SCALAPACK/build_tarballs.jl`):

```julia
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
# ...
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)   # if Fortran code
platforms, platform_dependencies = MPI.augment_platforms(platforms;
                                                        MPICH_compat="5",
                                                        OpenMPI_compat="4.1.9, 5.0.11")
augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""
append!(dependencies, platform_dependencies)
build_tarballs(...; augment_platform_block, ...)
```

`MPI.augment_platforms` expands each base platform into one variant per allowed ABI, adds an `mpi=<abi>` tag, and returns the matching `Dependency` list (including `MPIPreferences`).

Recurring gotchas:

- **MPItrampoline** does not support musl, Windows, or FreeBSD; **OpenMPI** is unavailable on `armv6l-linux-gnu`. The `mpi_abis` table in `platforms/mpi.jl` encodes most of this, but downstream recipes often still drop unsupported combinations with `filter!(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)` etc. (see `C/COSMA`, `C/COSTA`, `C/CryptoMiniSat`).
- **Fortran-bearing libraries** must call `expand_gfortran_versions(platforms)` *before* `MPI.augment_platforms`; C++-heavy packages often also need `expand_cxxstring_abis`.
- **Per-ABI linking** is selected with `if [[ ${bb_full_target} == *mpiabi* ]]; then …` blocks; each ABI exposes a different set of libraries (`libmpitrampoline`, `libmpi`+`libmpifort`, `libmpi`+`libmpi_mpifh`+`libmpi_usempif08`, `msmpi64`). `P/PETSc/build_tarballs.jl` is the canonical reference.
- **Windows (MicrosoftMPI)** needs `-DMPI_HOME=${prefix} -DMPI_GUESS_LIBRARY_NAME=MSMPI` and `-DMPI_${lang}_LIBRARIES=msmpi64` for CMake; see `H/HYPRE/build_tarballs.jl`.

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

- **Platforms:** Linux `x86_64-glibc`, Linux `aarch64-glibc` (split into `cuda_platform=jetson` vs `sbsa` for CUDA <13; unified for CUDA ≥13), and Windows `x86_64` (with caveats — `nvcc` is not a cross-compiler, so most recipes skip Windows). Musl and macOS are unsupported.
- **Supported toolkit versions** are listed in `CUDA.cuda_full_versions` in `platforms/cuda.jl`. Build one variant per CUDA minor; the `cuda=$MAJOR.$MINOR` platform tag drives selection.
- **`CUDA.augment` block is required** on consumers — it reads `CUDA_Runtime_jll` `Preferences` (`version`, `local`), detects driver capabilities via `CUDA_Driver_jll.inspect_driver`, and picks the highest-compatible toolkit. Compute-capability support is encoded in `cuda_cap_db` in `C/CUDA/CUDA_Runtime/platform_augmentation.jl`.
- **Build flags:** point CMake at the bundled toolkit with `-DCMAKE_CUDA_COMPILER=$prefix/cuda/bin/nvcc -DCMAKE_CUDA_FLAGS="-L${prefix}/cuda/lib"`. `nvcc` writes scratch to `/tmp` (small tmpfs in the sandbox); redirect with `export TMPDIR=${WORKSPACE}/tmpdir`.
- Pass **`static_sdk=true`** to `required_dependencies` when linking static CUDA libs (e.g. AMGX); this adds `CUDA_SDK_static_jll` as a `BuildDependency`.
- Always pass **`dont_dlopen=true`** and **`lazy_artifacts=true`** to `build_tarballs` for CUDA consumers — the runtime libs must not be dlopened at JLL init time.
- **NVIDIA redistributable archive** SHAs are published per CUDA release in `redistrib_<version>.json`; `cuda_nvcc_redist_source` / `get_sources` in `platforms/cuda.jl` and `C/CUDA/common.jl` handle this — prefer them over hand-rolled `ArchiveSource` URLs.

## Essential Structure

Every `build_tarballs.jl` file follows this pattern:

```julia
using BinaryBuilder

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
    Dependency("SomeDep_jll"),
    # BuildDependency("BuildOnlyDep_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
```

## Critical Rules

These are the hard requirements every recipe must satisfy. The "Build Script Reference"
section below is non-normative reference material (env vars, common build systems,
optional arguments).

### Naming

- **Name**: Must be a valid Julia identifier. Replace spaces/dashes with underscores. Generally match upstream casing, but use what makes most sense.
- **Version**: Only `X.Y.Z` format. Truncate any `-alpha`, `+build`, or 4+ level versions.
- **Products**: Export symbols should match the library/executable names (as symbols: `:libname`), but use what makes sense for the package.

### Sources

- **ArchiveSource**: For tarballs (`.tar.gz`, `.tar.xz`, `.zip`). Always include SHA256 hash.
- **GitSource**: For git repos. Use specific commit hash, not branch names.
- **DirectorySource**: For local patches. Place patches in `bundled/patches/` subdirectory.
- Build **one package per recipe**. Don't bundle multiple packages—use dependencies instead.

#### GitHub Archive Sources

**IMPORTANT**: GitHub's automatically generated archive sources (`/archive/refs/tags/` URLs) do **not** have stable checksums and cannot be used. See [GitHub's announcement](https://github.blog/2023-02-21-update-on-the-future-stability-of-source-code-archives-and-hashes/).

Instead:

1. **Use GitSource with commit hash** (preferred):

   ```julia
   sources = [
       GitSource("https://github.com/owner/repo.git", "full_commit_hash"),
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
git ls-remote https://github.com/owner/repo.git refs/tags/v1.0.0
```

### Products

- **LibraryProduct**: Shared libraries (`.so`, `.dylib`, `.dll`)
- **ExecutableProduct**: Binary executables
- **FileProduct**: Other files (headers, data files)
- **FrameworkProduct**: macOS frameworks

### Dependencies

- **Dependency**: Runtime dependency (will be a dependency of the generated JLL package)
- **BuildDependency**: Build-time only (not a dependency for the final JLL)
- **HostBuildDependency**: Build-time only dependency that needs to run on the build host, not target (not a dependency for the final JLL)

Always add `_jll` suffix: `Dependency("Zlib_jll")`

### GCC Version Selection

Use `preferred_gcc_version=v"X"` for (see [available GCC versions](https://github.com/JuliaPackaging/Yggdrasil/blob/master/RootFS.md#compiler-shards)):

- **C++ code**: Use oldest GCC that compiles (≤10 for Julia v1.6 compatibility)
- **Dependencies built with newer GCC**: Match or exceed their GCC version
- **Musl bugs**: Use GCC ≥6 to avoid `posix_memalign` issues
- Default is GCC 4.8.5 for maximum compatibility

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

**Rust** (add `compilers=[:c, :rust]`):

```bash
cargo build --release
install -Dm755 target/*/release/executable ${bindir}/executable
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
    clang_use_lld=false,                   # Use LLD linker
)
```

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
# Only 64-bit platforms
platforms = filter(p -> nbits(p) == 64, supported_platforms())

# Expand C++ string ABI variants
platforms = expand_cxxstring_abis(platforms)

# Expand Fortran library versions (only for Fortran codes)
platforms = expand_gfortran_versions(platforms)

# Specific platforms
platforms = [Platform("x86_64", "linux"), Platform("x86_64", "macos")]
```

### Setting Environment Variables

```bash
export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"
export PKG_CONFIG_PATH="${prefix}/lib/pkgconfig:${PKG_CONFIG_PATH}"
```

### Out-of-Source Builds

```bash
cd ${WORKSPACE}/srcdir
mkdir build && cd build
cmake ../package-source
```

## Testing Locally

```bash
julia --project=/path/to/Yggdrasil build_tarballs.jl --verbose --debug
```

Use `--debug` to get interactive shell on failure.

**Note**: On macOS, you need Docker installed for local testing.

## Common Issues

### Can't find headers/libraries

Add `-I${includedir}` to `CPPFLAGS` or `CFLAGS`/`CXXFLAGS`
Add `-L${libdir}` to `LDFLAGS`

### Old `config.sub`/`config.guess`

Call `update_configure_scripts` before `./configure`

### Foreign executable error

Can't run cross-compiled executables. Patch build system or build tools natively.

### Missing shared library on PowerPC

Regenerate configure: `autoreconf -vi` before `./configure`

### Link errors about unrecognized relocations

Increase `preferred_gcc_version` to match dependencies

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

Use `[skip build]` to publish JLL without rebuilding (for metadata-only changes like compat bounds).

## Testing JLL Packages Before Merging

Before merging a Yggdrasil PR, you should test the generated JLL package locally to ensure it works correctly. This avoids automatic registration of broken packages in the General registry.

### Step 0: Speed Up Testing (Optional)

For faster local testing, build only for your current platform by passing it as an argument to the build script:

```bash
julia --project=/path/to/Yggdrasil build_tarballs.jl --verbose --debug x86_64-linux-gnu
# Or for your current platform:
# x86_64-apple-darwin20 (macOS x86_64)
# aarch64-apple-darwin20 (macOS ARM64)
# x86_64-w64-mingw32 (Windows x86_64)
```

**Important**: Don't commit platform-specific builds - this is for local testing only.

### Step 1: Build the Package Locally

```bash
cd PackageName
julia --project=/path/to/Yggdrasil build_tarballs.jl --verbose
```

This creates tarballs in the `products/` directory.

### Step 2: Generate the JLL Package

Use BinaryBuilder to create a local JLL package from your build:

```julia
using BinaryBuilder

# Change to your package directory
cd("E/Electron")

# Run the build script to generate JLLs
run(`julia --project=/path/to/Yggdrasil build_tarballs.jl --deploy=local`)
```

Or directly from the command line:

```bash
julia --project=/path/to/Yggdrasil build_tarballs.jl --deploy=local
```

This generates a local JLL package in `~/.julia/dev/PackageName_jll/`.

### Step 3: Test the JLL Package

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

### Step 4: Test with Dependencies

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

### Step 5: Clean Up Before Pushing

After testing, clean up the local build artifacts:

```bash
# Remove generated products
rm -rf products/

# Remove the local JLL dev package (optional)
rm -rf ~/.julia/dev/PackageName_jll/
```

### Alternative: Use GitHub Actions Preview

For complex packages, you can also:

1. Push your branch to GitHub
2. Wait for the CI to build (creates artifacts)
3. Download the artifacts from the GitHub Actions run
4. Test the prebuilt binaries locally

### Common Issues When Testing

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

### What to Test

- [ ] All products are accessible and have correct paths
- [ ] Executables run without errors (at minimum `--version` or `--help`)
- [ ] Libraries can be loaded (`dlopen` doesn't fail)
- [ ] Dependencies are correctly linked
- [ ] Platform-specific behavior works (if applicable)
- [ ] Package imports without warnings or errors

## Reference Examples

- **Simple C library**: `Z/Zstd/build_tarballs.jl`
- **CMake with dependencies**: `C/CMake/build_tarballs.jl`
- **Autotools with patches**: Look for recipes with `bundled/patches/`
- **Platform-specific builds**: `G/Git/build_tarballs.jl`
- **Multiple sources**: `L/libftd2xx/build_tarballs.jl`

## MCP Tooling

This repo ships an MCP server for AI coding agents, configured in `.mcp.json`:

- **`bb-sandbox`** (`.claude/mcp-bb-sandbox/server.jl`) — launches and drives an
  interactive BinaryBuilder cross-compilation sandbox. Tools: `sandbox_start`,
  `sandbox_exec`, `sandbox_stop`, `sandbox_list`, `sandbox_str_replace_editor`.

The server runs from the `.ci/` Julia environment. On a fresh checkout it must
be instantiated once, otherwise the agent will fail to connect to `bb-sandbox`
because the server crashes on startup with a missing-package error
(e.g. `ClaudeMCPTools`). From the repo root:

```bash
julia --project=.ci -e 'using Pkg; Pkg.instantiate()'
```

After that, the agent's MCP status should show `bb-sandbox` connected.

## Additional Resources

- [BinaryBuilder Documentation](https://docs.binarybuilder.org)
- [Build Tips](https://docs.binarybuilder.org/stable/build_tips/)
- [Troubleshooting](https://docs.binarybuilder.org/stable/troubleshooting/)
- [CONTRIBUTING.md](CONTRIBUTING.md) in this repository
- [RootFS.md](RootFS.md) for compiler versions and cross-compilation details
