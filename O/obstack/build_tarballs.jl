# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "obstack"
version = v"1.1.1"

# Collection of sources required to build obstack
sources = [
    ArchiveSource("https://github.com/pullmoll/musl-obstack/archive/v$(version.major).$(version.minor).tar.gz",
                  "52a216613e7d55e8725e43d017bb2d49a4b1ffa1e06da472f03c7f9875df7d0d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/musl-obstack-*/
./bootstrap.sh
CFLAGS="-fPIC" ./configure --prefix=${prefix} --host=${target}
make -j${nproc}
make install
"""

# Select Unix platforms
platforms = [p for p in supported_platforms()]

# The products that we will ensure are always built
products = [
    LibraryProduct("libobstack", :libobstack),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
