# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GSL"
version_string = "2.8"
version = VersionNumber(version_string)

# Collection of sources required to build GSL
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/gsl/gsl-$(version_string).tar.gz",
                  "6a99eeed15632c6354895b1dd542ed5a855c0f15d9ad1326c6fe2b2c9e423190"),
    DirectorySource("./bundled"),
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

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/0001-remove-unknown-ld-option.patch
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=[Platform("aarch64", "freebsd")], experimental=true)

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
