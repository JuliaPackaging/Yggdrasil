# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXxf86vm"
version = v"1.1.6"

# Collection of sources required to build libXxf86vm
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libXxf86vm-$(version).tar.xz",
                  "96af414c73ce1d5449ad04be7f9f27fa8330f844b6dda843ef22e3e1befb3ee3"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXxf86vm-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-malloc0returnsnull=no --enable-static=no
make -j${nproc}
make install
"""

platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

products = Product[
    LibraryProduct("libXxf86vm", :libXxf86vm),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_util_macros_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Xorg_libXext_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
