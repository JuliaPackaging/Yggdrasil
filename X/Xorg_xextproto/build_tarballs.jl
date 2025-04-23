# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xextproto"
version = v"7.3.0"
# We bumped the version number because we built for riscv64
ygg_version = v"7.3.1"

# Collection of sources required to build xextproto
sources = [
    ArchiveSource("https://www.x.org/archive/individual/proto/xextproto-$(version).tar.bz2",
                  "f3f4b23ac8db9c3a9e0d8edb591713f3d70ef9c3b175970dd8823dfc92aa5bb0"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xextproto-*
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
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
