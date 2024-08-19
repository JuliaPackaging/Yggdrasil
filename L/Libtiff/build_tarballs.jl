# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libtiff"
version = v"4.6.0"

# Collection of sources required to build Libtiff
sources = [
    ArchiveSource("https://download.osgeo.org/libtiff/tiff-$(version).tar.xz",
                  "e178649607d1e22b51cf361dd20a3753f244f022eefab1f2f218fc62ebaf87d2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tiff-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --docdir=/tmp
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libtiff", :libtiff)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("JpegTurbo_jll"),
    # Can probably upgrade to LERC_jll@4 in next build
    Dependency("LERC_jll"; compat="3"),
    Dependency("XZ_jll"; compat="5.2.5"),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"; compat="1.5.6"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", clang_use_lld=false)
