# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libtiff"
upstream_version = v"4.7.2"
version = v"4.7.3" # Different version number because we needed to change compat bound, in the future we can go back to follow upstream

# Collection of sources required to build Libtiff
sources = [
    ArchiveSource("https://download.osgeo.org/libtiff/tiff-$(upstream_version).tar.xz",
                  "4996f0c4f93094719b1ca5c6279b20e588773ba8a247533e486416fb662ddb88"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tiff-*
# IDEA: disable tools, documentation, etc.?
# IDEA: enable jbig support
# IDEA: switch to using cmake?
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --docdir=/tmp --disable-static
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
    Dependency("JpegTurbo_jll"; compat="3.1.3"),
    Dependency("LERC_jll"; compat="4.0.1"),
    Dependency("XZ_jll"; compat="5.8.1"),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"; compat="1.5.7"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We need GCC 5 for C99
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"5")
