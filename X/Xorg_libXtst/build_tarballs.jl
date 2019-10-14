# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXtst"
version = v"1.2.3"

# Collection of sources required to build libXtst
sources = [
    "https://www.x.org/archive/individual/lib/libXtst-$(version).tar.bz2" =>
    "4655498a1b8e844e3d6f21f3b2c4e2b571effb5fd83199d428a6ba7ea4bf5204",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXtst-*/
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
    LibraryProduct("libXtst", :libXtst),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Xorg_inputproto_jll",
    "Xorg_libXext_jll",
    "Xorg_libXfixes_jll",
    "Xorg_libXi_jll",
    "Xorg_recordproto_jll",
    "Xorg_util_macros_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
