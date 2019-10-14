# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXdamage"
version = v"1.1.5"

# Collection of sources required to build libXdamage
sources = [
    "https://www.x.org/archive/individual/lib/libXdamage-$(version).tar.bz2" =>
    "b734068643cac3b5f3d2c8279dd366b5bf28c7219d9e9d8717e1383995e0ea45",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXdamage-*/
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
    LibraryProduct("libXdamage", :libXdamage),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Xorg_damageproto_jll",
    "Xorg_libXfixes_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
