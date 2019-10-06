# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXdmcp"
version = v"1.1.3"

# Collection of sources required to build libXdmcp
sources = [
    "https://www.x.org/archive/individual/lib/libXdmcp-$(version).tar.bz2" =>
    "20523b44aaa513e17c009e873ad7bbc301507a3224c232610ce2e099011c6529",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXdmcp-*/
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
    LibraryProduct("libXdmcp", :libXdmcp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Xorg_xproto_jll",
    "Xorg_util_macros_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
