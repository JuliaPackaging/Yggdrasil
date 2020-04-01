# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Clipper"
version = v"1.0.0"

# Collection of sources required to build Clipper
sources = [
    GitSource("https://github.com/SimonDanisch/ClipperBuilder.git",
              "9ea1878235d518d5e14bce35a94924a34bab8b68"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ClipperBuilder/
mkdir "${libdir}"
${CXX} -fPIC -std=c++11 -shared -o "${libdir}/libcclipper.${dlext}" clipper.cpp cclipper.cpp
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcclipper", :cclipper)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
