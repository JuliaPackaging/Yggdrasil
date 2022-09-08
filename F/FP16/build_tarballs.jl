# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FP16"
version = v"0.0.20210320"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Maratyszcza/FP16.git", "0a92994d729ff76a58f692d3028ca1b64b145d91"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/FP16
mkdir build
cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DFP16_BUILD_TESTS=OFF \
    -DFP16_BUILD_BENCHMARKS=OFF \
    ..
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("include/fp16.h", :fp16_h)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6")
