# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "ImageMagick"
version = v"6.9.10-12"

# Collection of sources required to build imagemagick
sources = [
    ArchiveSource("https://github.com/ImageMagick/ImageMagick6/archive/6.9.10-12.tar.gz",
    "efaae51489af9f895762bcb7090636f03194daaa026eda97dae230098d2ccec7"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ImageMagick6*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --without-x --disable-openmp --disable-installed --disable-dependency-tracking --without-frozenpaths --without-perl --disable-docs --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libMagickWand", "libMagickWand-6.Q16"], :libwand),
    ExecutableProduct("convert", :imagemagick_convert),
    ExecutableProduct("identify", :identify),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("libpng_jll"),
    Dependency("JpegTurbo_jll"),
    # TODO: v4.3.0 is available, use that next time
    Dependency("Libtiff_jll"; compat="4.1.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
