# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "at_spi2_atk"
version = v"2.34.1"

# Collection of sources required to build at-spi2-atk
sources = [
    "http://ftp.gnome.org/pub/gnome/sources/at-spi2-atk/$(version.major).$(version.minor)/at-spi2-atk-$(version).tar.xz" =>
    "776df930748fde71c128be6c366a987b98b6ee66d508ed9c8db2355bf4b9cc16",
    "./bundled"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/at-spi2-atk-*/

# Tests are failing to be built, just disable them
atomic_patch -p1 ../patches/meson_build.patch

mkdir build && cd build
meson .. --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if p isa Union{Linux,FreeBSD}]

# The products that we will ensure are always built
products = [
    LibraryProduct("libatk-bridge-2.0", :libatk_bridge),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "at_spi2_core_jll",
    "ATK_jll",
    "Xorg_libX11_jll",
    "XML2_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
