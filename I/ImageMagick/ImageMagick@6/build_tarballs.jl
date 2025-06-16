# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "ImageMagick"
upstream_version = v"6.9.13-25" # TODO: re-sync with upstream next release (+ 1 below was to update compat)
version = VersionNumber(
    upstream_version.major,
    upstream_version.minor,
    upstream_version.patch * 1000 + upstream_version.prerelease[1] + 1
)

# Collection of sources required to build imagemagick
sources = [
    GitSource("https://github.com/ImageMagick/ImageMagick6",
              "10f84a86515a7d9ec4c7a11d2249def100266846"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ImageMagick6*/

if [[ "${target}" == *86*-linux-gnu ]]; then
    # For `clock_gettime`
    atomic_patch -p1 ../patches/utilities-link-rt.patch
elif [[ "${target}" == *-mingw* ]]; then
    # For `clock_gettime`
    atomic_patch -p1 ../patches/check-have-clock-realtime.patch
    # otherwise autotools looks in ${prefix}/lib
    export LDFLAGS=-L${libdir}
fi

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
    LibraryProduct(["libMagickWand", "libMagickWand-6.Q16"], :libwand),
    ExecutableProduct("convert", :imagemagick_convert),
    ExecutableProduct("identify", :identify),
    ExecutableProduct("montage", :montage),
    ExecutableProduct("mogrify", :mogrify),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Ghostscript_jll"),
    Dependency("JpegTurbo_jll"),
    Dependency("Libtiff_jll"; compat="~4.5.1"),
    Dependency("OpenJpeg_jll"),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("libpng_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Using GCC 6 to get a newer libc, required by OpenJpeg that is pulled in by Libtiff
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"6")
