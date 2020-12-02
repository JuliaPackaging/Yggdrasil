# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GSL"
version = v"1.16"

# Collection of sources required to build GSL
sources = [
    "http://ftp.gnu.org/gnu/gsl/gsl-$(version.major).$(version.minor).tar.gz" =>
    "73bc2f51b90d2a780e6d266d43e487b3dbd78945dd0b04b14ca5980fe28d2f53",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gsl-*/
update_configure_scripts

# We need to massage configure script to convince it to build the shared library
# for PowerPC.
if [[ "${target}" == powerpc64le-* ]]; then
    autoreconf -vi
fi

./configure --prefix=$prefix --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built.
# Note that the products we are declaring here should be kept in-sync with those of `GSL@2`,
# so that users that don't care about versions can simply use (e.g. `libgsl`) without having
# to worry about whether `libgsl` is called something else in `GSL@2` versus `GSL@1`.
products = [
    LibraryProduct("libgsl", :libgsl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
