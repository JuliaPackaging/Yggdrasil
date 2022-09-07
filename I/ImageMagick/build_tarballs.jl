# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "ImageMagick"
upstream_version = v"6.9.12-62"
version = VersionNumber(upstream_version.major, upstream_version.minor, upstream_version.patch)

# Collection of sources required to build imagemagick
sources = [
    ArchiveSource("https://github.com/ImageMagick/ImageMagick6/archive/$(upstream_version).tar.gz",
                  "21eb4c5a4f0f9e76f1e67fb6a20f7b1e4374346ed9351bec9898f370d7b2f035"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ImageMagick6*/
if [[ "${target}" == *-linux-gnu ]]; then
    atomic_patch -p1 ../patches/utilities-link-rt.patch
elif [[ "${target}" == *-mingw* ]]; then
    # Link to ws2_32 to fix undefined reference to `__imp_WSAStartup`.
    atomic_patch -p1 ../patches/windows-undefined-reference-__imp_WSAStartup.patch
fi
atomic_patch -p1 ../patches/check-have-clock-realtime.patch
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
    --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(;experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct(["libMagickWand", "libMagickWand-6.Q16"], :libwand),
    ExecutableProduct("convert", :imagemagick_convert),
    ExecutableProduct("identify", :identify),
    ExecutableProduct("montage", :montage),
    ExecutableProduct("mogrify", :mogrify),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("libpng_jll"),
    Dependency("JpegTurbo_jll"),
    Dependency("Libtiff_jll"; compat="4.3.0"),
    Dependency("Ghostscript_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
