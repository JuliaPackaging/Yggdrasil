# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GSL"
version = v"2.6"

# Collection of sources required to build GSL
sources = [
    "http://ftp.gnu.org/gnu/gsl/gsl-$(version.major).$(version.minor).tar.gz" =>
    "b782339fc7a38fe17689cb39966c4d821236c28018b6593ddb6fd59ee40786a8",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gsl-*/

# We need to massage configure script to convince it to build the shared library
# for PowerPC.
if [[ "${target}" == powerpc64le-* ]]; then
    autoreconf -vi
fi

update_configure_scripts
./configure --prefix=$prefix --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgsl", :libgsl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
