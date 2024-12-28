# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_scrnsaverproto"
version = v"1.2.2"

# Collection of sources required to build scrnsaverproto
sources = [
    ArchiveSource("https://www.x.org/archive/individual/proto/scrnsaverproto-$(version).tar.bz2",
                  "8bb70a8da164930cceaeb4c74180291660533ad3cc45377b30a795d1b85bcd65"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/scrnsaverproto-*/
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
