# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Hwloc"
version = v"2.2.0"

# Collection of sources required to build hwloc
sources = [
    ArchiveSource("https://download.open-mpi.org/release/hwloc/v2.2/hwloc-$(version).tar.bz2", "ae70b893df272b84afd7068d351aae5c8c4fd79d40ca783b3e67554b873a2252")
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
products = [
    LibraryProduct("libhwloc", :libhwloc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

