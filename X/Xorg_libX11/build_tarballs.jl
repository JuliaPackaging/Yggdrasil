# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libX11"
version = v"1.6.8"

# Collection of sources required to build libX11
sources = [
    "https://www.x.org/archive/individual/lib/libX11-$(version).tar.bz2" =>
    "b289a845c189e251e0e884cc0f9269bbe97c238df3741e854ec4c17c21e473d5",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libX11-*/
CPPFLAGS="-I${prefix}/include"
# When compiling for things like ppc64le, we need newer `config.sub` files
update_configure_scripts
./configure --prefix=${prefix} --host=${target} --enable-malloc0returnsnull=no
# For some obscure reason, this Makefile may not get the value of CPPFLAGS
sed -i "s?CPPFLAGS = ?CPPFLAGS = ${CPPFLAGS}?" src/util/Makefile
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if p isa Union{Linux,FreeBSD}]

products = [
    LibraryProduct("libX11", :libX11),
    LibraryProduct("libX11-xcb", :libX11_xcb),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
