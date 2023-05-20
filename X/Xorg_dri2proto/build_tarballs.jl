# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_dri2proto"
version = v"2.8"

# Collection of sources required to build dri2proto
sources = [
    ArchiveSource("https://www.x.org/archive/individual/proto/dri2proto-$(version.major).$(version.minor).tar.bz2",
                  "f9b55476def44fc7c459b2537d17dbc731e36ed5d416af7ca0b1e2e676f8aa04"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/dri2proto-*/
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
