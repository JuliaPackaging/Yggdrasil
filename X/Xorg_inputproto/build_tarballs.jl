# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_inputproto"
version = v"2.3.2"

# Collection of sources required to build inputproto
sources = [
    "https://www.x.org/archive/individual/proto/inputproto-$(version).tar.bz2" =>
    "893a6af55733262058a27b38eeb1edc733669f01d404e8581b167f03c03ef31d",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/inputproto-*/
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
