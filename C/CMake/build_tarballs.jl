# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CMake"
version = v"3.24.3"

# Collection of sources required to build CMake
sources = [
    GitSource("https://github.com/Kitware/CMake",
              "c974557598645360fbabac71352b083117e3cc17"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/CMake/

cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_BUILD_TYPE:STRING=Release \
    -DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN \
    -DBUILD_TESTING:BOOL=OFF \
    -GNinja

ninja
ninja -j${nproc}
ninja install
"""

# Build for all supported platforms.
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("cmake", :cmake),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"; compat="1.1.10")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

