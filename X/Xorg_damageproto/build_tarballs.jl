# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_damageproto"
version = v"1.2.1"

# Collection of sources required to build damageproto
sources = [
    "https://www.x.org/archive/individual/proto/damageproto-$(version).tar.bz2" =>
    "5c7c112e9b9ea8a9d5b019e5f17d481ae20f766cb7a4648360e7c1b46fc9fc5b",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/damageproto-*/
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

products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
