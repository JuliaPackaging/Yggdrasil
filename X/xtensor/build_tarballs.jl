# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "xtensor"
version = v"0.25.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/xtensor-stack/xtensor", "3634f2ded19e0cf38208c8b86cea9e1d7c8e397d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xtensor
cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    # This is a header-only library without any binary products
    FileProduct("include/xtensor.hpp", :xtensor),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("xtl_jll"; compat="0.7.7"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
