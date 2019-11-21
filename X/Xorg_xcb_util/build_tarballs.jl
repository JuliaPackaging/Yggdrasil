# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xcb_util"
version = v"0.4.0"

# Collection of sources required to build xcb-util
sources = [
    "https://xcb.freedesktop.org/dist/xcb-util-$(version).tar.bz2" =>
    "46e49469cb3b594af1d33176cd7565def2be3fa8be4371d62271fabb5eae50e9",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xcb-util-*/
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
    LibraryProduct("libxcb-util", :libxcb_util),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Xorg_libxcb_jll"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
