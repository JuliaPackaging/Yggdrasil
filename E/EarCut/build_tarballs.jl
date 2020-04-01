
# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "EarCut"
version = v"2.1.5"
# Collection of sources required to build Clipper
sources = [
    GitSource("https://github.com/SimonDanisch/EarCutBuilder.git",
              "cfa4233e26ac785a89954a72b4e2e84312b389c2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/EarCutBuilder/
mkdir "${libdir}"
${CXX} -std=c++11 -fPIC -shared -o "${libdir}/libearcut.${dlext}" cwrapper.cpp
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libearcut", :libearcut)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
