# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "libyuv"
# This package doesn't have releases nor a version number
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://chromium.googlesource.com/libyuv/libyuv", "464c51a0353c71f08fe45f683d6a97a638d47833"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libyuv
cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
cmake --build build --parallel ${nproc}
cmake --install build
# Remove the static library (we don't want it)
rm ${libdir}/libyuv.a
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libyuv", :libyuv),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("JpegTurbo_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
