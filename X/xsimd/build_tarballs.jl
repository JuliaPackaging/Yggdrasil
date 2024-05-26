# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "xsimd"
version = v"13.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/xtensor-stack/xsimd", "5ac7edf30d0f519e0b7344b933382e4fc02fdee7"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xsimd
cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_XTL_COMPLEX=ON
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    # This is a header-only library without any binary products
    FileProduct("include/xsimd/xsimd.hpp", :xsimd),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("xtl_jll"; compat="0.7.7"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
