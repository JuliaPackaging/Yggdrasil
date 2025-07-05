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

mkdir build

args+=(-DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN)
args+=(-DCMAKE_INSTALL_PREFIX=$prefix)
args+=(-DCMAKE_BUILD_TYPE=RELEASE)

args+=(-DENABLE_FONTCONFIG=1)
args+=(-DENABLE_FREETYPE=1)
args+=(-DENABLE_ICONV=1)
args+=(-DENABLE_JPEG=1)
args+=(-DENABLE_TIFF=1)
args+=(-DENABLE_HEIF=1)
args+=(-DENABLE_AVIF=0)  # FIXME: fails
args+=(-DENABLE_WEBP=1)
args+=(-DENABLE_PNG=1)

cmake -B build -S . "${args[@]}"

cmake --build build --parallel $nproc
cmake --install build
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
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Fontconfig_jll"; compat="~2.16.0"),
    Dependency("FreeType2_jll"; compat="~2.13.4"),
    Dependency("Libtiff_jll"; compat="~4.7.1"),
    Dependency("libwebp_jll"; compat="~1.5.0"),
    Dependency("JpegTurbo_jll"),
    Dependency("Libiconv_jll"),
    # Dependency("libavif_jll"),  # FIXME: fails
    # Dependency("libheif_jll"),
    Dependency("libpng_jll"),
    Dependency("Zlib_jll"),
    Dependency(PackageSpec(; name="libheif_jll", uuid="a13778fd-9a17-58b4-b5a0-4b4a242815a9", path="$JULIA_HOME/dev/libheif_jll")),
    Dependency(PackageSpec(; name="libde265_jll", uuid="0a7f2b4d-d03c-5694-960e-196e69ee64e2", path="$JULIA_HOME/dev/libde265_jll")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version = v"10"
)
