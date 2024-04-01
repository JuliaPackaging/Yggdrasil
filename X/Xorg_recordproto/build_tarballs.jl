# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_recordproto"
version = v"1.14.2"

# Collection of sources required to build recordproto
sources = [
    ArchiveSource("https://www.x.org/archive/individual/proto/recordproto-$(version).tar.bz2",
                  "a777548d2e92aa259f1528de3c4a36d15e07a4650d0976573a8e2ff5437e7370"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/recordproto-*/
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
