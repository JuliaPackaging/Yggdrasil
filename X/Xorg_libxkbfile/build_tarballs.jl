# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libxkbfile"
version = v"1.1.0"

# Collection of sources required to build libxkbfile
sources = [
    "https://www.x.org/archive/individual/lib/libxkbfile-$(version).tar.bz2" =>
    "758dbdaa20add2db4902df0b1b7c936564b7376c02a0acd1f2a331bd334b38c7",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libxkbfile-*/
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
    LibraryProduct("libxkbfile", :libxkbfile),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Xorg_libX11_jll",
    "Xorg_util_macros_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
