# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "HighFive"
version = v"3.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/highfive-devs/highfive", "be0ddb3d43ce0f53db2d8b1438e819c5a5cb278a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/highfive
cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DHIGHFIVE_UNIT_TESTS=OFF \
    -DHIGHFIVE_EXAMPLES=OFF \
    -DHIGHFIVE_BUILD_DOCS=OFF
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = Product[
    # This is a header-only library without any binary products
    FileProduct("include/highfive/highfive.hpp", :highfive),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("HDF5_jll"; compat="2.0.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
