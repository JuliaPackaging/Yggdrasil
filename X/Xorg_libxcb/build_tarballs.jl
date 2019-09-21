# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg.BinaryPlatforms

name = "Xorg_libxcb"
version = v"1.13"

# Collection of sources required to build libxcb
sources = [
    "https://www.x.org/archive/individual/xcb/libxcb-$(version.major).$(version.minor).tar.bz2" =>
    "188c8752193c50ff2dbe89db4554c63df2e26a2e47b0fa415a70918b5b851daa",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libxcb-*/
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
