# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mpv"
version = v"0.41.0"

# Collection of sources required to complete build #
sources = [
    GitSource("https://github.com/mpv-player/mpv.git",
              "41f6a645068483470267271e1d09966ca3b9f413"),  # v0.41.0
    # macOS 11.3 SDK for Apple framework headers (CoreAudio, AVFoundation, etc.)
    FileSource("https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.3.sdk.tar.xz",
               "cd4f08a75577145b8f05245a2975f7c81401d75e9535dcffbb879ee1deefcbf4"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mpv

# Clone libplacebo as a meson subproject (needs --recursive for 3rdparty deps)
mkdir -p subprojects
git clone https://code.videolan.org/videolan/libplacebo.git \
    --branch v7.349.0 --depth=1 --recursive subprojects/libplacebo

# Remove host cmake so meson doesn't pick it up for cross-compilation
apk del cmake

# FFMPEG_jll installs pkgconfig files in ${libdir}/pkgconfig on Windows
if [[ "${target}" == *-mingw* ]]; then
    export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${libdir}/pkgconfig"
fi

FLAGS=()

if [[ "${target}" == *-apple-* ]]; then
    # x86_64-darwin14 sysroot lacks newer framework headers; overlay macOS 11.3 SDK
    # aarch64-darwin20 already has them so no SDK needed
    if [[ "${target}" == x86_64-apple-darwin* ]]; then
        rm -rf /opt/${target}/${target}/sys-root/System
        rm -rf /opt/${target}/${target}/sys-root/usr/include/libxml2/libxml
        tar --extract --file=${WORKSPACE}/srcdir/MacOSX11.3.sdk.tar.xz \
            --directory="/opt/${target}/${target}/sys-root/." \
            --strip-components=1 MacOSX11.3.sdk/System MacOSX11.3.sdk/usr
        export MACOSX_DEPLOYMENT_TARGET=11.0
    fi

    # Cocoa requires Swift (no Swift compiler in BinaryBuilder), so disable it
    # and all features that depend on it. CoreAudio/AVFoundation are independent.
    FLAGS+=(
        -Dcocoa=disabled
        -Dswift-build=disabled
        -Dgl-cocoa=disabled
        -Dmacos-cocoa-cb=disabled
        -Dmacos-media-player=disabled
        -Dmacos-touchbar=disabled
    )
fi

meson setup build --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release "${FLAGS[@]}"
meson compile -C build
meson install -C build

install_license Copyright LICENSE.GPL
"""

# Filter platforms that don't have full dependency support
platforms = supported_platforms()
filter!(p -> arch(p) != "armv6l", platforms)
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)
filter!(p -> arch(p) != "riscv64", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("mpv", :mpv)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("CMake_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Libiconv_jll"),
    Dependency("SDL2_jll"),
    Dependency("Zlib_jll"),
    Dependency("FFMPEG_jll"; compat="7.1"),
    Dependency("Lua_jll"),
    Dependency("JpegTurbo_jll"),
    Dependency("Xorg_libXrandr_jll"),
    Dependency("Xorg_libXinerama_jll"),
    Dependency("Libglvnd_jll"),
    Dependency("Xorg_libX11_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", clang_use_lld=false, preferred_gcc_version=v"8")
