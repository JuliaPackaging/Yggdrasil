# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Leptonica"
version = v"1.78.0"

# Collection of sources required to build Leptonica
sources = [
    ArchiveSource("http://www.leptonica.org/source/leptonica-$(version).tar.gz",
                  "e2ed2e81e7a22ddf45d2c05f0bc8b9ae7450545d995bfe28517ba408d14a5a88"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/leptonica-*/
./configure --prefix=$prefix --host=$target
make -j${nproc}
make install
install_license leptonica-license.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("liblept", :liblept),
    ExecutableProduct("convertfilestopdf", :convertfilestopdf),
    ExecutableProduct("convertfilestops", :convertfilestops),
    ExecutableProduct("convertformat", :convertformat),
    ExecutableProduct("convertsegfilestopdf", :convertsegfilestopdf),
    ExecutableProduct("convertsegfilestops", :convertsegfilestops),
    ExecutableProduct("converttopdf", :converttopdf),
    ExecutableProduct("converttops", :converttops),
    ExecutableProduct("fileinfo", :fileinfo),
    ExecutableProduct("imagetops", :imagetops),
    ExecutableProduct("xtractprotos", :xtractprotos),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Giflib_jll",
    "JpegTurbo_jll",
    "libpng_jll",
    "Libtiff_jll",
    "libwebp_jll",
    "Zlib_jll",
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
