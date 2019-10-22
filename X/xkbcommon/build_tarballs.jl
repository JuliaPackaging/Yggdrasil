# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "xkbcommon"
version = v"0.9.1"

# Collection of sources required to build xkbcommon
sources = [
    "https://xkbcommon.org/download/libxkbcommon-$(version).tar.xz" =>
    "d4c6aabf0a5c1fc616f8a6a65c8a818c03773b9a87da9fbc434da5acd1199be0",
    "./bundled"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libxkbcommon-*/

# We need to run `wayland-scanner` on the host system
apk add wayland-dev

atomic_patch -p1 ../patches/meson_build.patch
atomic_patch -p1 ../patches/meson_options.patch

mkdir build && cd build
meson .. --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Denable-docs=false \
    -Dnative-wayland-scanner="/usr/bin/wayland-scanner"
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if p isa Linux]

# The products that we will ensure are always built
products = [
    LibraryProduct("libxkbcommon", :libxkbcommon),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Xorg_xkeyboard_config_jll",
    "Xorg_libxcb_jll",
    "Wayland_jll",
    "Wayland_protocols_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
