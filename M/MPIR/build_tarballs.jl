# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "MPIR"
version = v"3.0.0"

# Collection of sources required to build MPFRBuilder
sources = [
    "http://mpir.org/mpir-$(version).tar.bz2" =>
    "52f63459cf3f9478859de29e00357f004050ead70b45913f2c2269d9708675bb",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mpir-*

# We need `yasm`
apk add yasm

./configure --enable-cxx --prefix=$prefix --host=${target} --disable-static --enable-shared
make -j
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if arch(p) == :x86_64 && !isa(p, FreeBSD)]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libmpir", :libmpir)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
