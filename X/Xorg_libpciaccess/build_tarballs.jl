# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libpciaccess"
version = v"0.18.1"

# Collection of sources required to build Libpciaccess
sources = [
    ArchiveSource("https://xorg.freedesktop.org/releases/individual/lib/libpciaccess-$(version).tar.xz",
                  "4af43444b38adb5545d0ed1c2ce46d9608cc47b31c2387fc5181656765a6fa76"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libpciaccess-*/
meson setup builddir --buildtype=release --cross-file=${MESON_TARGET_TOOLCHAIN} --prefix=${prefix}
meson compile -C builddir
meson install -C builddir
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
    Dependency("Zlib_jll"; compat="1.2.12"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
