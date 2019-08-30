# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Expat"
version = v"2.2.7"

# Collection of sources required to build Expat
sources = [
    "https://github.com/libexpat/libexpat/releases/download/R_$(version.major)_$(version.minor)_$(version.patch)/expat-$(version).tar.xz" =>
    "30e3f40acf9a8fdbd5c379bdcc8d1178a1d9af306de29fc8ece922bc4c57bef8",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/expat-*/
./configure --prefix=$prefix --host=$target
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libexpat", :libexpat),
    ExecutableProduct("xmlwf", :xmlwf)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
