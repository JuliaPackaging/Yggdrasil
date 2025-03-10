# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mpv"
version = v"0.39.0"

# Collection of sources required to complete build #
sources = [
    GitSource("https://github.com/mpv-player/mpv.git", "a0fba7be57f3822d967b04f0f6b6d6341e7516e7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mpv

apk del cmake

mkdir -p subprojects
git clone https://code.videolan.org/videolan/libplacebo.git --depth=1 --recursive subprojects/libplacebo

meson --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release setup build
meson compile -C build
meson install -C build
"""

# We pick the same platforms FFMPEG_jll does 
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
    Dependency("FFMPEG_jll"),
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

