# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xtrans"
version = v"1.6.0"

# Collection of sources required to build xtrans
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/xtrans-$(version).tar.xz",
                  "faafea166bf2451a173d9d593352940ec6404145c5d1da5c213423ce4d359e92"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xtrans-*
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
