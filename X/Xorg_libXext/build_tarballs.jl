# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXext"
version = v"1.3.4"

# Collection of sources required to build libXext
sources = [
    "https://www.x.org/archive/individual/lib/libXext-$(version).tar.bz2" =>
    "59ad6fcce98deaecc14d39a672cf218ca37aba617c9a0f691cac3bcd28edf82b",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXext-*/
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
    LibraryProduct("libXext", :libXext),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Xorg_libX11_jll",
    "Xorg_xextproto_jll",
    "Xorg_util_macros_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
