# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libepoxy"
version = v"1.5.10"

# Collection of sources required to build Libepoxy
sources = [
    ArchiveSource("https://github.com/anholt/libepoxy/archive/refs/tags/$(version).tar.gz",
                  "a7ced37f4102b745ac86d6a70a9da399cc139ff168ba6b8002b4d8d43c900c15")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libepoxy-*/
mkdir build && cd build
meson .. -Dtests=false --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libepoxy", :libepoxy),
]

linux_freebsd = filter(p->Sys.islinux(p)||Sys.isfreebsd(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libglvnd_jll"),
    Dependency("Xorg_libX11_jll"; platforms=linux_freebsd),
    BuildDependency("Xorg_xorgproto_jll"; platforms=linux_freebsd),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
