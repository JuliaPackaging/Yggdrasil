# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GSL"
version = v"2.6"

# Collection of sources required to build GSL
sources = [
    ArchiveSource("http://ftp.gnu.org/gnu/gsl/gsl-$(version.major).$(version.minor).tar.gz",
                  "b782339fc7a38fe17689cb39966c4d821236c28018b6593ddb6fd59ee40786a8"),
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

# The products that we will ensure are always built
products = [
    LibraryProduct("libgslcblas", :libgslcblas),
    LibraryProduct("libgsl", :libgsl),
    ExecutableProduct("gsl-histogram", :gsl_histogram),
    ExecutableProduct("gsl-randist", :gsl_randist),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
