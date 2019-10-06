# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_util_macros"
version = v"1.19.2"

# Collection of sources required to build xorg-util-macros
sources = [
    "https://www.x.org/archive/individual/util/util-macros-$(version).tar.bz2" =>
    "d7e43376ad220411499a79735020f9d145fdc159284867e99467e0d771f3e712",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/util-macros-*/
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
