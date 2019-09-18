# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "ImageMagick"
version = v"6.9.10-12"

# Collection of sources required to build imagemagick
sources = [
    "https://github.com/ImageMagick/ImageMagick6/archive/6.9.10-12.tar.gz" =>
    "efaae51489af9f895762bcb7090636f03194daaa026eda97dae230098d2ccec7",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ImageMagick6*/
./configure --prefix=$prefix --host=$target --without-x --disable-openmp --disable-installed --disable-dependency-tracking --without-frozenpaths --without-perl
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libMagickWand", "libMagickWand-6.Q16"], :libwand),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Zlib_jll",
    "libpng_jll",
    "JpegTurbo_jll",
    "Libtiff_jll"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
