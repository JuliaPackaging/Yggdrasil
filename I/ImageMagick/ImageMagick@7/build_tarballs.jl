# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "ImageMagick"
upstream_version = v"7.1.1-47"
version = VersionNumber(upstream_version.major, upstream_version.minor, upstream_version.patch)

# Collection of sources required to build imagemagick
sources = [
    GitSource("https://github.com/ImageMagick/ImageMagick",
              "82572afc879b439cbf8c9c6f3a9ac7626adf98fb"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ImageMagick*/
atomic_patch -p1 ../patches/check-have-clock-realtime.patch
atomic_patch -p1 ../patches/urlmon.patch
./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --without-x \
    --disable-openmp \
    --disable-installed \
    --disable-dependency-tracking \
    --without-frozenpaths \
    --without-perl \
    --disable-docs \
    --disable-static \
    --with-gslib
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libMagickWand", "libMagickWand-7.Q16HDRI"], :libwand),
    ExecutableProduct("convert", :imagemagick_convert),
    ExecutableProduct("identify", :identify),
    ExecutableProduct("montage", :montage),
    ExecutableProduct("mogrify", :mogrify),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Ghostscript_jll"),
    Dependency("JpegTurbo_jll"),
    Dependency("LERC_jll"),
    Dependency("Libtiff_jll"; compat="4.7.1"),
    Dependency("LittleCMS_jll"),
    Dependency("OpenJpeg_jll"),
    Dependency("Zlib_jll"),
    Dependency("libpng_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Using GCC 6 to get a newer libc, required by OpenJpeg that is pulled in by Libtiff
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"6")
