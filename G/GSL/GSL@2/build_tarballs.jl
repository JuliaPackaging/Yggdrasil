# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GSL"
version_string = "2.7.1"
version = v"2.7.2" # <--- This version number is a lie to keep it different from our
                   # previous fake "2.7.1" build, as they have different ABI because of
                   # https://git.savannah.gnu.org/cgit/gsl.git/commit/configure.ac?id=77e7c7d008707dace56626020eaa6181912e9841

# Collection of sources required to build GSL
sources = [
    ArchiveSource("http://ftp.gnu.org/gnu/gsl/gsl-$(version_string).tar.gz",
                  "dcb0fbd43048832b757ff9942691a8dd70026d5da0ff85601e52687f6deeb34b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gsl-*/
if [[ "${target}" == aarch64-apple-darwin* ]]; then
    # aclocal.m4 has some lines where it expects `MACOSX_DEPLOYMENT_TARGET` to be up to
    # version 10.  Let's pretend to be 10.16, as many tools do to make old build systems
    # happy.
    export MACOSX_DEPLOYMENT_TARGET="10.16"
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static
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
dependencies = [
    # For some reasons only on macOS we need a BLAS library
    Dependency("OpenBLAS_jll"; compat="", platforms=filter(Sys.isapple, platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
