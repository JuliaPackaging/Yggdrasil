# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libX11"
version = v"1.8.12"

# Collection of sources required to build libX11
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libX11-$(version).tar.xz",
                  "fa026f9bb0124f4d6c808f9aef4057aad65e7b35d8ff43951cef0abe06bb9a9a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libX11-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p->!(Sys.islinux(p) || Sys.isfreebsd(p)))


products = [
    LibraryProduct("libX11", :libX11),
    LibraryProduct("libX11-xcb", :libX11_xcb),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    BuildDependency("Xorg_util_macros_jll"),
    Dependency("Xorg_libxcb_jll"),
    Dependency("Xorg_xtrans_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
