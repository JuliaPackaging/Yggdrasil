# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xorgproto"
version = v"2024.1"

# Collection of sources required to build xproto
sources = [
    ArchiveSource("https://www.x.org/archive/individual/proto/xorgproto-$(version.major).$(version.minor).tar.gz",
                  "4f6b9b4faf91e5df8265b71843a91fc73dc895be6210c84117a996545df296ce"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xorgproto-*/
CPPFLAGS="-I${prefix}/include"
# When compiling for things like ppc64le, we need newer `config.sub` files
update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-malloc0returnsnull=no
make -j${nproc}
make install
install_license COPYING-*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
