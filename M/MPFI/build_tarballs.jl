# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MPFI"
version = v"1.5.4"
# We needed to bump the version to build for new architectures
ygg_version = v"1.5.6"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/arpra-project/mpfi", "446e21250c82c9d156e7b83b6119013943664942"),
]

# Bash recipe for building across all platforms
script = raw"""
    cd $WORKSPACE/srcdir/mpfi

    # The autotools scripts are not provided setup, so we must configure the configure script
    ./autogen.sh

    # Don't build the static library, documentation, or test set
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-gmp=${prefix} --with-mpfr=${prefix} --disable-static CFLAGS=-Wno-incompatible-pointer-types
    make -j${nproc} SUBDIRS="src"
    make install SUBDIRS="src"

    # Remove the libtool files that are created
    rm -f ${prefix}/lib/*.la
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmpfi", :libmpfi)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll"; compat="6.2.1"),
    Dependency("MPFR_jll"; compat="4.2.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
