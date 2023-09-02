# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "ORTools"
version = v"9.7"

# Collection of sources required to build this package
sources = [
    GitSource("https://github.com/google/or-tools.git",
              "35d56a4b07db8ea135b83762289fbc0e7d229221"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/or-tools*
mkdir build
cmake -S. -Bbuild \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DBUILD_DEPS:BOOL=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_EXAMPLES:BOOL=OFF \
    -DBUILD_SAMPLES:BOOL=OFF \
    -DUSE_SCIP:BOOL=ON \
    -DUSE_HIGHS:BOOL=OFF \
    -DUSE_COINOR:BOOL=OFF \
    -DUSE_GLPK:BOOL=OFF
cmake --build build
cmake --build build --target install
"""

# TODO: generate with ProtoBuf.jl.
# TODO: disable SCIP.

platforms = [
    Platform("x86_64", "linux"),
    # Platform("aarch64", "linux"),
    # Platform("x86_64", "macos"),
    # Platform("aarch64", "macos"),
    # Platform("x86_64", "freebsd"),
    # Platform("x86_64", "windows")
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libortools", :libortools),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"10", julia_compat="1.6")
