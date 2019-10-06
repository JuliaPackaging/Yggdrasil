# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXScrnSaver"
version = v"1.2.3"

# Collection of sources required to build libXScrnSaver
sources = [
    "https://www.x.org/archive/individual/lib/libXScrnSaver-$(version).tar.bz2" =>
    "f917075a1b7b5a38d67a8b0238eaab14acd2557679835b154cf2bca576e89bf8",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXScrnSaver-*/
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
    LibraryProduct("libXss", :libXScrnSaver),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Xorg_scrnsaverproto_jll",
    "Xorg_libXext_jll",
    "Xorg_util_macros_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
