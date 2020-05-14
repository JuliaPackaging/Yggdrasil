# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MPFI"
version = v"1.5.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gforge.inria.fr/frs/download.php/file/38111/mpfi-1.5.4.tgz", "3b3938595d720af17973deaf727cfc0dd41c8b16c20adc103a970f4a43ae3a56"),
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
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmpfi", :libmpfi)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GMP_jll",  uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"))
    Dependency(PackageSpec(name="MPFR_jll", uuid="3a97d323-0669-5f0c-9066-3539efd106a3"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
