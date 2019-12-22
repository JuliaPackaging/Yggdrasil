# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Tesseract"
version = v"4.1.0"

# Collection of sources required to build Tesseract
sources = [
    "https://github.com/tesseract-ocr/tesseract/archive/$(version).tar.gz" =>
    "5c5ed5f1a76888dc57a83704f24ae02f8319849f5c4cf19d254296978a1a1961",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tesseract-*/
./autogen.sh
./configure --prefix=$prefix --host=$target
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Giflib_jll",
    "JpegTurbo_jll",
    "libpng_jll",
    "Libtiff_jll",
    "Zlib_jll",
    "Leptonica_jll",
    # Optional dependencies
    # "ICU_jll",
    "Cairo_jll",
    "Pango_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
