# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXrender"
version = v"0.9.10"

# Collection of sources required to build libXrender
sources = [
    "https://www.x.org/archive/individual/lib/libXrender-$(version).tar.bz2" =>
    "c06d5979f86e64cabbde57c223938db0b939dff49fdb5a793a1d3d0396650949",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXrender-*/
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
    LibraryProduct("libXrender", :libXrender),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Xorg_libX11_jll",
    "Xorg_renderproto_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
