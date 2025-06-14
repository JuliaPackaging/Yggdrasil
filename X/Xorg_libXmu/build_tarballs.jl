# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXmu"
version = v"1.2.1"

# Collection of sources required to build libXmu
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libXmu-$(version).tar.xz",
                  "fcb27793248a39e5fcc5b9c4aec40cc0734b3ca76aac3d7d1c264e7f7e14e8b2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXmu-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

products = [
    LibraryProduct("libXmu", :libXmu),
    LibraryProduct("libXmuu", :libXmuu),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_kbproto_jll"),
    BuildDependency("Xorg_xproto_jll"),
    BuildDependency("Xorg_util_macros_jll"),
    BuildDependency("Xorg_xextproto_jll"),
    Dependency("Xorg_libXext_jll"),
    Dependency("Xorg_libXt_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
