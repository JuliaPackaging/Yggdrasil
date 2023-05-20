# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xineramaproto"
version = v"1.2.1"

# Collection of sources required to build xineramaproto
sources = [
    ArchiveSource("https://www.x.org/archive/individual/proto/xineramaproto-$(version).tar.bz2",
                  "977574bb3dc192ecd9c55f59f991ec1dff340be3e31392c95deff423da52485b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xineramaproto-*/
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
