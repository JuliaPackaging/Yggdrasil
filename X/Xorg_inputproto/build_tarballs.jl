# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_inputproto"
version = v"2.3.2"
# We bumped the version number because we converted the package to
# AnyPlatform, which required rebuilding the package, which implicitly
# changed the compat bounds
ygg_version = v"2.3.3"

# Collection of sources required to build inputproto
sources = [
    ArchiveSource("https://www.x.org/archive/individual/proto/inputproto-$(version).tar.bz2",
               "893a6af55733262058a27b38eeb1edc733669f01d404e8581b167f03c03ef31d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/inputproto-*
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
