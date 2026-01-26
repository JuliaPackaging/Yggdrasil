# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXft"
version = v"2.3.9"

# Collection of sources required to build libXft
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libXft-$(version).tar.xz",
                  "60a25b78945ed6932635b3bb1899a517d31df7456e69867ffba27f89ff3976f5"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXft-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-static=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

products = [
    LibraryProduct("libXft", :libXft),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_kbproto_jll"),
    BuildDependency("Xorg_renderproto_jll"),
    BuildDependency("Xorg_xproto_jll"),
    Dependency("Fontconfig_jll"),
    Dependency("Xorg_libXrender_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
