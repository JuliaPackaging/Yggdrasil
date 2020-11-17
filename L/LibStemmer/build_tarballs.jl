# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LibStemmer"
version = v"0.1"

# Collection of sources required to build FriBidi
sources = [
    GitSource("https://github.com/zvelo/libstemmer.git",
              "78c149a3a6f262a35c7f7351d3f77b725fc646cf")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libstemmer/
sed -i -e 's/ADD_LIBRARY(stemmer/ADD_LIBRARY(stemmer SHARED/' CMakeLists.txt
sed -i -e 's/DESTINATION lib/RUNTIME DESTINATION bin LIBRARY DESTINATION lib/' CMakeLists.txt
cmake -DCMAKE_INSTALL_PREFIX=$WORKSPACE/destdir
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libstemmer", :libstemmer)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
