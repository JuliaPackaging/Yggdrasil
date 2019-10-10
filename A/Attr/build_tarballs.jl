# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Attr"
version = v"2.4.48"

# Collection of sources required to build attr
sources = [
    "https://download.savannah.gnu.org/releases/attr/attr-$(version).tar.gz" =>
    "5ead72b358ec709ed00bbf7a9eaef1654baad937c001c044fe8b74c57f5324e7",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/attr-*/
./configure --prefix=${prefix} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = [p for p in supported_platforms() if p isa Linux]

# The products that we will ensure are always built
products = [
    LibraryProduct("libattr", :attr),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
