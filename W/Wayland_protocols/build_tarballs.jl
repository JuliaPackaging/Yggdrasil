# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Wayland_protocols"
version = v"1.44"

# Collection of sources required to build Wayland-protocols
sources = [
    ArchiveSource("https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/$(version.major).$(version.minor)/downloads/wayland-protocols-$(version.major).$(version.minor).tar.xz",
                  "3df1107ecf8bfd6ee878aeca5d3b7afd81248a48031e14caf6ae01f14eebb50e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wayland-protocols*/

# Find wayland-scanner and create symlink where Meson expects it
WAYLAND_SCANNER=$(which wayland-scanner)
if [ -n "$WAYLAND_SCANNER" ]; then
    echo "Found wayland-scanner at: $WAYLAND_SCANNER"
    
    # Create the exact directory structure that Meson expects
    EXPECTED_PATH="/workspace/${bb_full_target}/destdir${host_prefix}/lib/pkgconfig/../../bin"
    mkdir -p "$EXPECTED_PATH"
    ln -sf "$WAYLAND_SCANNER" "$EXPECTED_PATH/wayland-scanner"
fi

mkdir build && cd build
meson setup .. -Dtests=false --cross-file="${MESON_TARGET_TOOLCHAIN}"
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
