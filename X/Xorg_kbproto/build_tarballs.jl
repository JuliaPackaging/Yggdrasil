# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_kbproto"
version = v"1.0.7"

# Collection of sources required to build kbproto
sources = [
    ArchiveSource("https://www.x.org/archive/individual/proto/kbproto-$(version).tar.bz2",
               "f882210b76376e3fa006b11dbd890e56ec0942bc56e65d1249ff4af86f90b857")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/kbproto-*/
CPPFLAGS="-I${prefix}/include"
# When compiling for things like ppc64le, we need newer `config.sub` files
update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-malloc0returnsnull=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
