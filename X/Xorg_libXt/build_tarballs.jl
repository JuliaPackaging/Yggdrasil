# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXt"
version = v"1.3.1"

# Collection of sources required to build libXt
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libXt-$(version).tar.xz",
                  "e0a774b33324f4d4c05b199ea45050f87206586d81655f8bef4dba434d931288"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXt-*

# Correct syntax error in header file
# (Already fixed upstream.)
atomic_patch -p1 $WORKSPACE/srcdir/patches/Xtos.h.patch

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

products = [
    LibraryProduct("libXt", :libXt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_util_macros_jll"),
    BuildDependency("Xorg_kbproto_jll"),
    BuildDependency("Xorg_xproto_jll"),
    Dependency("Xorg_libICE_jll"),
    Dependency("Xorg_libSM_jll"),
    Dependency("Xorg_libX11_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
