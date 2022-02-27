# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "isoband"
version = v"0.2.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jeremiahpslewis/isoband.git", "e9cac53f18cc7e9e8da8b01a1122cd65d9fa68f2")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir -p ${libdir}
$CXX -shared -std=c++11 -O3 -fPIC -o ${libdir}/libisoband.${dlext} isoband/src/isoband.cpp
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libisoband", :libisoband)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
