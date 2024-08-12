# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_randrproto"
version = v"1.5.0"

# Collection of sources required to build randrproto
sources = [
    ArchiveSource("https://www.x.org/archive/individual/proto/randrproto-$(version).tar.bz2",
                  "4c675533e79cd730997d232c8894b6692174dce58d3e207021b8f860be498468"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/randrproto-*/
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
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
