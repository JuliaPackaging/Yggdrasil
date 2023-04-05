# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Blosc2"
version = v"2.8.0"

# Collection of sources required to build Blosc2
sources = [
    GitSource("https://github.com/Blosc/c-blosc2.git", "8de035e5147397e3008a61ae1e2e6fcc949319f0"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/c-blosc2/
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=OFF \
    -DBUILD_BENCHMARKS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_STATIC=OFF \
    -DCMAKE_SHARED_LIBRARY_LINK_C_FLAGS="" \
    -DPREFER_EXTERNAL_ZLIB=ON \
    -DPREFER_EXTERNAL_ZSTD=ON \
    -DPREFER_EXTERNAL_LZ4=ON \
    ..
make -j${nproc}
make install
install_license ../LICENSES/*.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# Build errors on armv7l; see <https://github.com/Blosc/c-blosc2/issues/465>
platforms = filter(p -> arch(p) ≠ "armv7l", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libblosc2", :libblosc2),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"),
    Dependency("Lz4_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We need at least GCC 8 for powerpc.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
