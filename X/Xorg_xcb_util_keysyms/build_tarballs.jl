# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xcb_util_keysyms"
version = v"0.4.0"

# Collection of sources required to build libxcb
sources = [
    "https://xcb.freedesktop.org/dist/xcb-util-keysyms-$(version).tar.bz2" =>
    "0ef8490ff1dede52b7de533158547f8b454b241aa3e4dcca369507f66f216dd9",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xcb-util-keysyms-*/
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
    LibraryProduct("libxcb-keysyms", :libxcb_keysyms),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Xorg_xcb_util_jll"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
