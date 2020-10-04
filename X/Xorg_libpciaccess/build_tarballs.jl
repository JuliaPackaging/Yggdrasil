# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libpciaccess"
version = v"0.16"

# Collection of sources required to build Libpciaccess
sources = [
    ArchiveSource("https://xorg.freedesktop.org/releases/individual/lib/libpciaccess-$(version.major).$(version.minor).tar.bz2",
                  "214c9d0d884fdd7375ec8da8dcb91a8d3169f263294c9a90c575bf1938b9f489"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libpciaccess-*/
./configure --prefix=${prefix} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

# The products that we will ensure are always built
products = [
    LibraryProduct("libpciaccess", :libpciaccess),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_util_macros_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
