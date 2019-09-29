# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg.BinaryPlatforms

name = "Wayland_protocols"
version = v"1.18"

# Collection of sources required to build Wayland-protocols
sources = [
    "https://wayland.freedesktop.org/releases/wayland-protocols-$(version.major).$(version.minor).tar.xz" =>
    "3d73b7e7661763dc09d7d9107678400101ecff2b5b1e531674abfa81e04874b3",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wayland-protocols-*/
./configure --prefix=${prefix} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if p isa Linux]

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Wayland_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
