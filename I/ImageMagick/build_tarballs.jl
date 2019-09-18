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
if [[ ${target} == *-apple-* ]]; then
    # Work around the "size too large (archive member
    # extends past the end of the file)" issue
    AR=/opt/${target}/bin/${target}-ar
fi
./configure --prefix=$prefix --host=$target --without-x --disable-openmp --disable-installed --disable-dependency-tracking --without-frozenpaths --without-perl
make -j${nproc}
make install

if [[ ${target} == *-apple-* ]]; then
    echo "-- Modifying link references for ImageMagick libraries"
    opts=""
    # for some reason libtiff and libpng don't need help?
    for XLIB in libMagick++-6.Q16.8 libMagickCore-6.Q16.6 libMagickWand-6.Q16.6 libjpeg.9 libz.1
    do
        opts="${opts} -change ${WORKSPACE}/destdir/lib/${XLIB}.dylib @rpath/${XLIB}.dylib"
    done
    for YLIB in libMagickWand-6.Q16.6 libMagickCore-6.Q16.6 libMagick++-6.Q16.8
    do
        install_name_tool ${opts} ${prefix}/lib/${YLIB}.dylib
    done
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libMagickWand", :libwand),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Zlib_jll",
    "Libpng_jll",
    "JpegTurbo_jll",
    "Libtiff_jll"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
