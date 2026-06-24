using BinaryBuilder, Pkg

function yggdrasil_version(version::VersionNumber, offset::VersionNumber)
    max_offset = v"10.100.1000"
    @assert offset < max_offset
    VersionNumber(
        max_offset.major * version.major + offset.major,
        max_offset.minor * version.minor + offset.minor,
        max_offset.patch * version.patch + offset.patch
    )
end

name = "LibGD"
version = v"2.3.3"
ygg_offset = v"0.0.0"  # NOTE: increase on new build, reset on new upstream version
ygg_version = yggdrasil_version(version, ygg_offset)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/libgd/libgd/releases/download/gd-$version/libgd-$version.tar.gz",
                  "dd3f1f0bb016edcc0b2d082e8229c822ad1d02223511997c80461481759b1ed2"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libgd-*

# for release 2.3.3, remove in 2.3.4 (adapted from https://github.com/libgd/libgd/pull/828)
atomic_patch -p1 -l ${WORKSPACE}/srcdir/patches/allow-mingw-for-webpng.patch

mkdir build

args+=(-DCMAKE_TOOLCHAIN_FILE=$CMAKE_TARGET_TOOLCHAIN)
args+=(-DCMAKE_INSTALL_PREFIX=$prefix)
args+=(-DCMAKE_BUILD_TYPE=RELEASE)

args+=(-DENABLE_FONTCONFIG=1)
args+=(-DENABLE_GD_FORMATS=1)
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

install_license COPYING
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
    Dependency("Fontconfig_jll"),
    Dependency("FreeType2_jll"),
    Dependency("Libtiff_jll"; compat="~4.7.1"),
    Dependency("libwebp_jll"; compat="1.5.0"),
    Dependency("JpegTurbo_jll"),
    Dependency("Libiconv_jll"),
    Dependency("libheif_jll"),
    # Dependency("libavif_jll"),  # FIXME: fails
    Dependency("libpng_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version = v"9"
)
