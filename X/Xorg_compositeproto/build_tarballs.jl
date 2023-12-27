# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_compositeproto"
version = v"0.4"

# Collection of sources required to build compositeproto
sources = [
    ArchiveSource("https://www.x.org/archive/individual/proto/compositeproto-$(version.major).$(version.minor).tar.bz2",
                  "6013d1ca63b2b7540f6f99977090812b899852acfbd9df123b5ebaa911e30003"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/compositeproto-*/
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
