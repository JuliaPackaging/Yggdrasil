# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GEOS"
version = v"3.8.0"

# Collection of sources required to build GEOS
sources = [
    "http://download.osgeo.org/geos/geos-$version.tar.bz2" =>
    "99114c3dc95df31757f44d2afde73e61b9f742f0b683fd1894cbbee05dda62d5",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/geos-*/
./configure --prefix=$prefix --host=$target
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgeos_c", :libgeos),
    LibraryProduct("libgeos", :libgeos_cpp)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
