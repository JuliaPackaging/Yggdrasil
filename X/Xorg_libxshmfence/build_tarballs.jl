# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libxshmfence"
version = v"1.3"

# Collection of sources required to build libxshmfence
sources = [
    "https://www.x.org/archive/individual/lib/libxshmfence-$(version.major).$(version.minor).tar.bz2" =>
    "b884300d26a14961a076fbebc762a39831cb75f92bed5ccf9836345b459220c7",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libxshmfence-*/
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
    LibraryProduct("libxshmfence", :libxshmfence),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Xorg_util_macros_jll",
    "Xorg_xproto_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
