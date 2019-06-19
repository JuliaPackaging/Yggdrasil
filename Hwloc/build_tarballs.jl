# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "hwloc"
version = v"2.0.4"

# Collection of sources required to build hwloc
sources = [
    "https://download.open-mpi.org/release/hwloc/v2.0/hwloc-$(version).tar.bz2" =>
    "653c05742dff16e5ee6ad3343fd40e93be8ba887eaffbd539832b68780d047a9",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hwloc-*
./configure --prefix=$prefix --host=$target
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libhwloc", :libhwloc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

