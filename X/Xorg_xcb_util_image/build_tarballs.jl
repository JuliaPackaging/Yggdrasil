# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xcb_util_image"
version = v"0.4.0"

# Collection of sources required to build libxcb
sources = [
    "https://xcb.freedesktop.org/dist/xcb-util-image-$(version).tar.bz2" =>
    "2db96a37d78831d643538dd1b595d7d712e04bdccf8896a5e18ce0f398ea2ffc",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xcb-util-image-*/
CPPFLAGS="-I${prefix}/include"

# When compiling for things like ppc64le, we need newer `config.sub` files
update_configure_scripts

./configure --prefix=${prefix} --host=${target} --enable-malloc0returnsnull=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if p isa Union{Linux,FreeBSD}]

products = [
    LibraryProduct("libxcb-image", :libxcb_image),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Xorg_xcb_util_jll"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
