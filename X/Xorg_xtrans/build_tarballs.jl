# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xtrans"
version = v"1.4.0"

# Collection of sources required to build xtrans
sources = [
    "https://www.x.org/archive/individual/lib/xtrans-$(version).tar.bz2" =>
    "377c4491593c417946efcd2c7600d1e62639f7a8bbca391887e2c4679807d773",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xtrans-*/
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
