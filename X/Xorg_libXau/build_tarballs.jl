# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXau"
version = v"1.0.9"

# Collection of sources required to build libXau
sources = [
    "https://www.x.org/archive/individual/lib/libXau-$(version).tar.bz2" =>
    "ccf8cbf0dbf676faa2ea0a6d64bcc3b6746064722b606c8c52917ed00dcb73ec",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXau-*/
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
    LibraryProduct("libXau", :libXau),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Xorg_xproto_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
