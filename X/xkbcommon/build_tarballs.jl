# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "xkbcommon"
version = v"1.4.1"

# Collection of sources required to build xkbcommon
sources = [
    ArchiveSource("https://xkbcommon.org/download/libxkbcommon-$(version).tar.xz",
                  "943c07a1e2198026d8102b17270a1f406e4d3d6bbc4ae105b9e1b82d7d136b39"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libxkbcommon-*/
apk add wayland-dev
mkdir build && cd build
meson .. --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Denable-docs=false
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l" && Sys.islinux(p), supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libxkbcommon", :libxkbcommon),
    LibraryProduct("libxkbcommon-x11", :libxkbcommon_x11),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Xorg_xkeyboard_config_jll"),
    Dependency("Xorg_libxcb_jll"),
    Dependency("Wayland_jll"),
    Dependency("Wayland_protocols_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
