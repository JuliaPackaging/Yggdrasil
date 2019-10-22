# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXft"
version = v"2.3.3"

# Collection of sources required to build libXft
sources = [
    "https://www.x.org/archive/individual/lib/libXft-$(version).tar.bz2" =>
    "225c68e616dd29dbb27809e45e9eadf18e4d74c50be43020ef20015274529216",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXft-*/
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
    LibraryProduct("libXft", :libXft),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Fontconfig_jll",
    "Xorg_libXrender_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
