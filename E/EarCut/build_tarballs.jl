# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "EarCut"
# use https://github.com/mapbox/earcut.hpp/releases/tag/v2.2.3
version = v"2.2.3"
sources = [
    GitSource("https://github.com/mapbox/earcut.hpp.git",
              "b28acde132cdb8e0ef536a96ca7ada8a651f9169"),
    DirectorySource("./bundled")

]

# Bash recipe for building across all platforms
script = raw"""
cp $WORKSPACE/srcdir/earcut.hpp/include/mapbox/earcut.hpp ./earcut.h
mkdir "${libdir}"
${CXX} -std=c++11 -fPIC -shared -o "${libdir}/libearcut.${dlext}" cwrapper.cpp
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libearcut", :libearcut)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
