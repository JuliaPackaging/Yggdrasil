# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GSL"
version = v"2.5.0"

# Collection of sources required to build GSL
sources = [
    "http://ftp.gnu.org/gnu/gsl/gsl-2.5.tar.gz" =>
    "0460ad7c2542caaddc6729762952d345374784100223995eb14d614861f2258d",
]

# Bash recipe for building across all platforms
script = raw"""
AR=/opt/${target}/bin/ar
cd $WORKSPACE/srcdir/gsl-*/
./configure --prefix=$prefix --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libgsl", :libgsl)
]

# Dependencies that must be installed before this package can be built
dependencies = [

]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
