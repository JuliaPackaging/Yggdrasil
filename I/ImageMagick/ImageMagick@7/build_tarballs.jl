# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "ImageMagick"
upstream_version = v"7.1.2-3"
version = VersionNumber(
    upstream_version.major,
    upstream_version.minor,
    upstream_version.patch * 1000 + upstream_version.prerelease[1] + 2
)

# Collection of sources required to build imagemagick
sources = [
    GitSource("https://github.com/ImageMagick/ImageMagick",
              "147bc9c12ce8fbc1e94af5b5f6f0643ca410103a"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ImageMagick*/

atomic_patch -p1 ../patches/check-have-clock-realtime.patch
atomic_patch -p1 ../patches/urlmon.patch

export LDFLAGS="${LDFLAGS} -L${libdir}"

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
    ExecutableProduct("magick", :magick),
    ExecutableProduct("montage", :montage),
    ExecutableProduct("mogrify", :mogrify),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Ghostscript_jll"; compat="9.55.1"),
    Dependency("Libtiff_jll"; compat="4.7.1"),
    Dependency("OpenJpeg_jll"),
    Dependency("JpegTurbo_jll"; compat="3.0.4"),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("FFTW_jll"),
    Dependency("libpng_jll"),
    Dependency("libwebp_jll"),
    Dependency("libzip_jll"),
    Dependency("Bzip2_jll"),
    Dependency("Zstd_jll"),
#    Dependency("Fontconfig_jll"),
#    Dependency("FreeType2_jll"),
#    Dependency("Pango_jll"),
#    Dependency("Librsvg_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Using GCC 6 to get a newer libc, required by OpenJpeg that is pulled in by Libtiff
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"9")
