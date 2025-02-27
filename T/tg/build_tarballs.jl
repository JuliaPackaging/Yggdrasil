# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "tg"
upstream_version = v"0.7.2"
version = v"0.7.2" # Different version number because we needed to change compat bound, in the future we can go back to follow upstream

# Collection of sources required to build Libtiff
sources = [
    GitSource("https://github.com/tidwall/tg.git",
                  "8fcb9b2809ad696025b4618ad226140f9ddbc452"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tg
clang -shared -o tg.so -fPIC -g -O3 tg.c
mkdir lib
mv tg.so lib/
mkdir include
mv tg.h include/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("tg", :tg),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    ]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
