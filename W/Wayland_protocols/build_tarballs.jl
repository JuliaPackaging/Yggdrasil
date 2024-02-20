# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Wayland_protocols"
version = v"1.31"

# Collection of sources required to build Wayland-protocols
sources = [
    ArchiveSource("https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/$(version.major).$(version.minor)/downloads/wayland-protocols-$(version.major).$(version.minor).tar.xz",
                  "a07fa722ed87676ec020d867714bc9a2f24c464da73912f39706eeef5219e238"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wayland-protocols*/
mkdir build && cd build
meson .. -Dtests=false --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]


# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Wayland_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
