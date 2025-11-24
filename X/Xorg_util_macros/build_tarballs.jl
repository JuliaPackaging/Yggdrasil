# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_util_macros"
version = v"1.20.2"

# Collection of sources required to build xorg-util-macros
sources = [
    ArchiveSource("https://www.x.org/archive/individual/util/util-macros-$(version).tar.xz",
                  "9ac269eba24f672d7d7b3574e4be5f333d13f04a7712303b1821b2a51ac82e8e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/util-macros-*/
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
