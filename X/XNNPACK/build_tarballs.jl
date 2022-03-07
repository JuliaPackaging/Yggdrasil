# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "XNNPACK"
version = v"0.0.20200225"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/google/XNNPACK.git", "7493bfb9d412e59529bcbced6a902d44cfa8ea1c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/XNNPACK
mkdir build
cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DXNNPACK_LIBRARY_TYPE=shared \
    -DXNNPACK_BUILD_TESTS=OFF \
    -DXNNPACK_BUILD_BENCHMARKS=OFF \
    ..
cmake --build . -- -j $nproc
make install
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libXNNPACK", :libxnnpack),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("CPUInfo_jll", v"0.0.20200122"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"9",
    julia_compat="1.6")
