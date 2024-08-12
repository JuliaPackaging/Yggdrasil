# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_dri3proto"
version = v"1.0"

# Collection of sources required to build dri3proto
sources = [
    ArchiveSource("https://www.x.org/archive/individual/proto/dri3proto-$(version.major).$(version.minor).tar.bz2",
                  "01be49d70200518b9a6b297131f6cc71f4ea2de17436896af153226a774fc074"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/dri3proto-*/
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
