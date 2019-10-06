# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXrandr"
version = v"1.5.2"

# Collection of sources required to build libXrandr
sources = [
    "https://www.x.org/archive/individual/lib/libXrandr-$(version).tar.bz2" =>
    "8aea0ebe403d62330bb741ed595b53741acf45033d3bda1792f1d4cc3daee023",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXrandr-*/
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
    LibraryProduct("libXrandr", :libXrandr),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Xorg_libXext_jll",
    "Xorg_libXrender_jll",
    "Xorg_randrproto_jll",
    "Xorg_util_macros_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
