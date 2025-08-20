# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libtiff"
upstream_version = v"4.7.0"
version = v"4.7.1" # Different version number because we needed to change compat bound, in the future we can go back to follow upstream

# Collection of sources required to build Libtiff
sources = [
    ArchiveSource("https://download.osgeo.org/libtiff/tiff-$(upstream_version).tar.xz",
                  "273a0a73b1f0bed640afee4a5df0337357ced5b53d3d5d1c405b936501f71017"),
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
    Dependency("LERC_jll"; compat="4.0.1"),
    Dependency("XZ_jll"; compat="5.6.4"),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"; compat="1.5.7"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", clang_use_lld=false)
