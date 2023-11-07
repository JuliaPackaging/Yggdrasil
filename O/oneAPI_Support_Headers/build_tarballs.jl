# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oneAPI_Support_Headers"
version = v"2023.11.7"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/oneapi-src/level-zero.git", "ea5be99d8d34480447ab1e3c7efc30d6f179b123"),
    GitSource("https://github.com/oneapi-src/oneCCL.git", "bfc879266e870b732bd165e399897419c44ad13d"),
    GitSource("https://github.com/oneapi-src/oneDNN.git", "22b933f7f53d1e1e79496070027d9702114cf1cc"),
    GitSource("https://github.com/oneapi-src/oneMKL.git", "5696f3aa974910d8c8cf90c2c1663c20ffc2a5a1"),
    # GitSource("https://github.com/oneapi-src/oneDPL.git", "c93a31cf7fe4870f34aec8ed38685b499e80ef48"),
    # GitSource("https://github.com/oneapi-src/oneTBB.git", "7b8018f0bc34e66c06e99551860551171ec60e31"),
]

# Bash recipe for building across all platforms
script = raw"""
mkdir $includedir
cp -r oneCCL/include $includedir/oneCCL
cp -r oneDNN/include $includedir/oneDNN
cp -r oneMKL/include $includedir/oneMKL
cp -r level-zero/include $includedir/level-zero
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("include/oneCCL/oneapi/ccl.hpp", :ccl_hpp),
    FileProduct("include/oneDNN/dnnl.hpp", :dnnl_hpp),
    FileProduct("include/oneMKL/oneapi/mkl.hpp", :mkl_hpp)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
