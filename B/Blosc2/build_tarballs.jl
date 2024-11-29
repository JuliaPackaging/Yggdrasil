1# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Blosc2"

upstream_version = v"2.15.2"
# We add a version offset because:
# - Blosc2 2.15 is not ABI-compatible with Blosc2 2.14
#   (see the release notes <https://github.com/Blosc/c-blosc2/releases/tag/v2.15.0>)
# - We updated the compat bounds
version_offset = v"1.0.1"
version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                        upstream_version.minor * 100 + version_offset.minor,
                        upstream_version.patch * 100 + version_offset.patch)

# Collection of sources required to build Blosc2
sources = [
    GitSource("https://github.com/Blosc/c-blosc2.git", "f1278b90056a99c35592e964f549f1f2ba13f05c"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/c-blosc2

# Blosc2 mis-detects whether the system headers provide `_xsetbv`
# (probably on several platforms), and on `x86_64-w64-mingw32` the
# functions have incompatible return types (although both are 64-bit
# integers).
atomic_patch -p1 ../patches/_xsetbv.patch

# Clang on Apple does not (yet?) properly support `__builtin_cpu_supports`.
# The symbol `__cpu_model` is not provided by any standard library.
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    perl -pi -e 's/#define HAVE_CPU_FEAT_INTRIN/#undef HAVE_CPU_FEAT_INTRIN/' blosc/shuffle.c
fi

cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_BENCHMARKS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_STATIC=OFF \
    -DBUILD_TESTS=OFF \
    -DPREFER_EXTERNAL_LZ4=ON  \
    -DPREFER_EXTERNAL_ZLIB=ON \
    -DPREFER_EXTERNAL_ZSTD=ON
cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSES/*.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libblosc2", :libblosc2),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Lz4_jll"; compat="1.10.0"),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"; compat="1.5.6"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We need at least GCC 8 for powerpc.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
