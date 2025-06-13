# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xcb_proto"
version_string = "1.17.0"
# We bumped the version number because we built for additional architectures
version = v"1.17.1"

# Collection of sources required to build xcb-proto
sources = [
    ArchiveSource("https://www.x.org/archive/individual/xcb/xcb-proto-$(version_string).tar.xz",
                  "2c1bacd2110f4799f74de6ebb714b94cf6f80fb112316b1219480fd22562148c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xcb-proto-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p->!(Sys.islinux(p) || Sys.isfreebsd(p)))

products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
