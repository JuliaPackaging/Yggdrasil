# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xf86vidmodeproto"
version = v"2.3.1"

# Collection of sources required to build xf86vidmodeproto
sources = [
    "https://www.x.org/archive/individual/proto/xf86vidmodeproto-$(version).tar.bz2" =>
    "45d9499aa7b73203fd6b3505b0259624afed5c16b941bd04fcf123e5de698770",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xf86vidmodeproto-*/
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

products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
