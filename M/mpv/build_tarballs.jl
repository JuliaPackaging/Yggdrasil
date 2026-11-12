# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "mpv"
version = v"0.42.0"

# Collection of sources required to complete build #
sources = [
    GitSource("https://github.com/mpv-player/mpv.git", "b0841e8c4d156b8403dc1876c4cbd9011eb583f3"; tag="v$(version)"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mpv

# Some libc headers define `strcspn` as a macro; the comma in the compound
# literal then splits the macro arguments. Parenthesize the literal.
atomic_patch -p1 $WORKSPACE/srcdir/patches/screenshot-strcspn-macro.patch

# Clone libplacebo as a meson subproject (needs --recursive for 3rdparty deps)
mkdir -p subprojects
git clone https://code.videolan.org/videolan/libplacebo.git \
    --branch v7.387.0 --depth=1 --recursive subprojects/libplacebo

# Remove host cmake so meson doesn't pick it up for cross-compilation
apk del cmake

# FFMPEG_jll installs pkgconfig files in ${libdir}/pkgconfig on Windows
if [[ "${target}" == *-mingw* ]]; then
    export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:+${PKG_CONFIG_PATH}:}${libdir}/pkgconfig"
fi

# On FreeBSD, HarfBuzz_jll and FriBidi_jll (needed by libass) ship their
# pkg-config files in libdata/pkgconfig
if [[ "${target}" == *-freebsd* ]]; then
    export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:+${PKG_CONFIG_PATH}:}${prefix}/libdata/pkgconfig"
fi

FLAGS=()

if [[ "${target}" == *-apple-* ]]; then
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

if [[ "${target}" == *-mingw* ]]; then
    # The d3d11 video output needs spirv-cross, which we don't provide, so
    # mpv's d3d11_helpers.c is not compiled. But the (auto-enabled) D3D11VA
    # hwaccel filter vf_d3d11vpp.c still uses it, which fails at link time
    # (undefined reference to `mp_params_to_dxgi_colorspace`). Disable it;
    # this also disables the dependent d3d9-hwaccel.
    FLAGS+=(-Dd3d-hwaccel=disabled)
fi

if [[ "${target}" == i686-*-mingw* ]]; then
    # The i686 mingw-w64 ole32 import library lacks CoIncrementMTAUsage@4 and
    # CoDecrementMTAUsage@4, which ao_wasapi.c needs (undefined reference at
    # link time). Disable WASAPI there; SDL2 audio remains available.
    FLAGS+=(-Dwasapi=disabled)
fi

# SDL2 video/audio are disabled by default in mpv 0.41; enable them explicitly
# Vulkan is disabled: not native on macOS, stdcall ABI issues on 32-bit Windows,
# and SDL2+OpenGL provide sufficient video output for a JLL package
FLAGS+=(-Dsdl2-video=enabled -Dsdl2-audio=enabled -Dvulkan=disabled)

meson setup build --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release "${FLAGS[@]}"
meson compile -C build
meson install -C build

install_license Copyright LICENSE.GPL
"""

sources, script = require_macos_sdk("11.3", sources, script)

# Filter platforms that don't have full dependency support
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("mpv", :mpv),
    LibraryProduct("libmpv", :libmpv),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("CMake_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("FFMPEG_jll"; compat="9.0.0"),
    Dependency("JpegTurbo_jll"),
    Dependency("Libglvnd_jll"),
    Dependency("Libiconv_jll"),
    Dependency("Lua_jll"),
    Dependency("SDL2_jll"),
    Dependency("Shaderc_jll"),
    Dependency("Xorg_libX11_jll"),
    Dependency("Xorg_libXinerama_jll"),
    Dependency("Xorg_libXrandr_jll"),
    Dependency("Zlib_jll"),
    Dependency("libass_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", clang_use_lld=false, preferred_gcc_version=v"8")
