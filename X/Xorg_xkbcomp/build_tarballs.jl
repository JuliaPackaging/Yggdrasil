# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xkbcomp"
version = v"1.4.2"

# Collection of sources required to build xkbcomp
sources = [
    "https://www.x.org/archive/individual/app/xkbcomp-$(version).tar.bz2" =>
    "6dd8bcb9be7e85bd7294abe261b8c7b0539d2fc93e41b80fb8bd013767ce8424",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xkbcomp-*
./configure --prefix=${prefix} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if p isa Union{Linux,FreeBSD}]

products = [
    ExecutableProduct("xkbcomp", :xkbcomp)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Xorg_libxkbfile_jll",
    "Xorg_util_macros_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
