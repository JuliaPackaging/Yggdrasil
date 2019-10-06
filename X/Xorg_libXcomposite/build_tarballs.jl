# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXcomposite"
version = v"0.4.5"

# Collection of sources required to build libXcomposite
sources = [
    "https://www.x.org/archive/individual/lib/libXcomposite-$(version).tar.bz2" =>
    "b3218a2c15bab8035d16810df5b8251ffc7132ff3aa70651a1fba0bfe9634e8f",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXcomposite-*/
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
    LibraryProduct("libXcomposite", :libXcomposite),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Xorg_compositeproto_jll",
    "Xorg_libXfixes_jll",
    "Xorg_util_macros_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
