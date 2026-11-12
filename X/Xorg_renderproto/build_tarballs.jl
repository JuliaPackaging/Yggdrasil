# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_renderproto"
version = v"0.11.1"
ygg_version = v"0.11.2"         # we converted to AnyPlatform

# Collection of sources required to build renderproto
sources = [
    ArchiveSource("https://www.x.org/archive/individual/proto/renderproto-$(version).tar.bz2",
               "06735a5b92b20759204e4751ecd6064a2ad8a6246bb65b3078b862a00def2537")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/renderproto-*
# When compiling for things like ppc64le, we need newer `config.sub` files
update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
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
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies; julia_compat="1.6")
