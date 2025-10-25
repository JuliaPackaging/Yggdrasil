# Agent Guide for Yggdrasil Build Scripts

This guide helps AI agents generate correct `build_tarballs.jl` recipes for BinaryBuilder.jl in the Yggdrasil repository.

## Prerequisites

- **BinaryBuilder.jl**: Requires Julia 1.7 specifically (use `julia +1.7` if juliaup is installed)
- **Supported Platforms**: Linux (glibc and musl for x86_64, i686, aarch64, armv7l, armv6l, ppc64le, riscv64), Windows (x86_64, i686), macOS (x86_64, aarch64), FreeBSD (x86_64, aarch64)
- Use `supported_platforms()` to get all available platforms

## Special Dependencies

Some dependencies require special handling:

- **LLVM packages**: Must use `LLVM_full_jll` and match the version used by the Julia version. Requires careful ABI compatibility.
- **MPI packages**: Need `MPIPreferences.jl` configuration and must use `MPItrampoline_jll` for cross-implementation compatibility.
- **CUDA packages**: Use `CUDA.required_dependencies` to get the necessary runtime dependencies. Must handle different CUDA versions. GPU code needs special compilation flags.

For these complex dependencies, consult existing recipes in the repository (search for `LLVM_full_jll`, `MPItrampoline_jll`, or `CUDA.required_dependencies`).

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

### Naming

- **Name**: Must be a valid Julia identifier. Replace spaces/dashes with underscores. Generally match upstream casing, but use what makes most sense.
- **Version**: Only `X.Y.Z` format. Truncate any `-alpha`, `+build`, or 4+ level versions.
- **Products**: Export symbols should match the library/executable names (as symbols: `:libname`), but use what makes sense for the package.

### Sources

- **ArchiveSource**: For tarballs (`.tar.gz`, `.tar.xz`, `.zip`). Always include SHA256 hash.
- **GitSource**: For git repos. Use specific commit hash, not branch names.
- **DirectorySource**: For local patches. Place patches in `bundled/patches/` subdirectory.
- Build **one package per recipe**. Don't bundle multiple packages—use dependencies instead.

### Build Script

The script runs in `x86_64-linux-musl` environment. Key variables:

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


### Optional Arguments

```julia
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.10",                   # Minimum Julia version
    preferred_gcc_version=v"8",            # GCC version
    preferred_llvm_version=v"13",          # LLVM version
    compilers=[:c, :rust],                 # Additional compilers
    clang_use_lld=false,                   # Use LLD linker
)
```

### Unsupported Build Flags

Products should not force using certain CPUs or instruction sets (e.g., the `march` or `mcpu` flags), unless they perform their own selection of the appropriate code for the current processor at runtime.
They also should not use unsafe math operations or the "fast math" mode in compilters.

To remove the `march` and `mcpu` flags in a list of files:
```bash
for i in ${files}
    sed -i "s/-march[^ ]*//g" $i
    sed -i "s/-mcpu[^ ]*//g" $i
done
```

To remove the fast math and unsafe math optimizations in a list of files:
```bash
for i in ${files}
    sed -i "s/-ffast-math//g" $i
    sed -i "s/-funsafe-math-optimizations//g" $i
done
```

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
julia +1.7 --project=/path/to/Yggdrasil build_tarballs.jl --verbose --debug
```

Use `--debug` to get interactive shell on failure. If you have juliaup installed, use `julia +1.7` to ensure Julia 1.7 is used.

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
julia +1.7 --project=/path/to/Yggdrasil build_tarballs.jl --verbose --debug x86_64-linux-gnu
# Or for your current platform:
# x86_64-apple-darwin20 (macOS x86_64)
# aarch64-apple-darwin20 (macOS ARM64)
# x86_64-w64-mingw32 (Windows x86_64)
```

**Important**: Don't commit platform-specific builds - this is for local testing only.

### Step 1: Build the Package Locally

```bash
cd PackageName
julia +1.7 --project=/path/to/Yggdrasil build_tarballs.jl --verbose
```

This creates tarballs in the `products/` directory.

### Step 2: Generate the JLL Package

Use BinaryBuilder to create a local JLL package from your build:

```julia
using BinaryBuilder

# Change to your package directory
cd("E/Electron")

# Run the build script to generate JLLs
run(`julia +1.7 --project=/path/to/Yggdrasil build_tarballs.jl --deploy=local`)
```

Or directly from the command line:

```bash
julia +1.7 --project=/path/to/Yggdrasil build_tarballs.jl --deploy=local
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
@info "Executable path:" PackageName_jll.executable_name()

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

## Additional Resources

- [BinaryBuilder Documentation](https://docs.binarybuilder.org)
- [Build Tips](https://docs.binarybuilder.org/stable/build_tips/)
- [Troubleshooting](https://docs.binarybuilder.org/stable/troubleshooting/)
- [CONTRIBUTING.md](CONTRIBUTING.md) in this repository
- [RootFS.md](RootFS.md) for compiler versions and cross-compilation details

