# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXi"
version = v"1.7.10"

# Collection of sources required to build libXi
sources = [
    "https://www.x.org/archive/individual/lib/libXi-$(version).tar.bz2" =>
    "36a30d8f6383a72e7ce060298b4b181fd298bc3a135c8e201b7ca847f5f81061",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXi-*/
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
    LibraryProduct("libXi", :libXi),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Xorg_inputproto_jll",
    "Xorg_libXext_jll",
    "Xorg_libXfixes_jll",
    "Xorg_util_macros_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
