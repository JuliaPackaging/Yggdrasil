using BinaryBuilder, Pkg

name = "LibGD"
version = v"2.3.3"
ygg_build = 0  # NOTE: increase on new build, reset on new upstream version
ygg_version = VersionNumber(version.major, version.minor, version.patch * 1_000 + ygg_build)

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/libgd/libgd.git",
              "b5319a41286107b53daa0e08e402aa1819764bdc")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libgd

./bootstrap.sh
./configure --help

args+=(--prefix=${prefix})
args+=(--build=${MACHTYPE})
args+=(--host=${target})
args+=(--with-fontconfig)
args+=(--with-freetype)
args+=(--with-jpeg)
args+=(--with-tiff)
args+=(--with-webp)
args+=(--with-zlib)
args+=(--with-png)

./configure "${args[@]}"

# For some reasons (something must be off in the configure script), on some
# platforms the build system tries to use iconv but without adding the `-liconv`
# flag.  Give a hint to make to use the right flag everywhere
make -j${nproc} LIBICONV="-liconv" LTLIBICONV="-liconv"
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("pngtogd2", :pngtogd2),
    ExecutableProduct("webpng", :webpng),
    ExecutableProduct("pngtogd", :pngtogd),
    ExecutableProduct("gdtopng", :gdtopng),
    ExecutableProduct("gdcmpgif", :gdcmpgif),
    ExecutableProduct("gd2topng", :gd2topng),
    ExecutableProduct("gdparttopng", :gdparttopng),
    ExecutableProduct("gd2copypal", :gd2copypal),
    ExecutableProduct("gd2togif", :gd2togif),
    ExecutableProduct("giftogd2", :giftogd2),
    LibraryProduct("libgd", :libgd),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("JpegTurbo_jll"),
    Dependency("Zlib_jll"),
    Dependency("libpng_jll"),
    Dependency("Libtiff_jll"; compat="~4.7.1"),
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Libiconv_jll"),
    Dependency("libwebp_jll"; compat="~1.5.0"),
    Dependency("Fontconfig_jll"; compat="~2.16.0"),
    Dependency("FreeType2_jll"; compat="~2.13.4"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies; julia_compat="1.6")
