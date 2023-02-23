# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "EarCut"
# use https://github.com/mapbox/earcut.hpp/releases/tag/v2.2.4
version = v"2.2.4"
sources = [
    GitSource("https://github.com/mapbox/earcut.hpp.git",
              "4811a2b69b91f6127a75e780de6e2113609ddabb"),
    DirectorySource("./bundled")

]

# Bash recipe for building across all platforms
script = raw"""
cp $WORKSPACE/srcdir/earcut.hpp/include/mapbox/earcut.hpp ./earcut.h
mkdir "${libdir}"
${CXX} -std=c++11 -fPIC -shared -o "${libdir}/libearcut.${dlext}" cwrapper.cpp
install_license earcut.hpp/LICENSE
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
