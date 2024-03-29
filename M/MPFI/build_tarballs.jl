# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MPFI"
version = v"1.5.5"# <-- This is a lie, we're bumping from 1.5.4 to 1.5.5 to create a Julia v1.6+ release with experimental platforms

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://mirror.eu.oneandone.net/linux/distributions/gentoo/gentoo/distfiles/3a/mpfi-1.5.4.tgz", "3b3938595d720af17973deaf727cfc0dd41c8b16c20adc103a970f4a43ae3a56"),
]

# Bash recipe for building across all platforms
script = raw"""
    cd $WORKSPACE/srcdir/mpfi-*

    # The autotools scripts are not provided setup, so we must configure the configure script
    ./autogen.sh

    # Don't build the static library, documentation, or test set
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-gmp=${prefix} --with-mpfr=${prefix} --disable-static
    make -j${nproc} SUBDIRS="src"
    make install SUBDIRS="src"

    # Remove the libtool files that are created
    rm -f ${prefix}/lib/*.la
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmpfi", :libmpfi)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.2.0"),
    Dependency("MPFR_jll", v"4.1.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
