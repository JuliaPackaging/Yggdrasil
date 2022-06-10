# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GSL"
version = v"2.7.2" # <--- This version number is a lie
real_version = v"2.7.1"

# Collection of sources required to build GSL
sources = [
    ArchiveSource("http://ftp.gnu.org/gnu/gsl/gsl-$(real_version).tar.gz",
                  "efbbf3785da0e53038be7907500628b466152dbc3c173a87de1b5eba2e23602b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gsl-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
