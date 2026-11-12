# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libxkbfile"
version = v"1.2.0"

# Collection of sources required to build libxkbfile
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libxkbfile-$(version).tar.xz",
                  "7f71884e5faf56fb0e823f3848599cf9b5a9afce51c90982baeb64f635233ebf"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libxkbfile-*
meson setup builddir --cross-file="${MESON_TARGET_TOOLCHAIN}" --buildtype=release
meson compile -C builddir -j${nproc}
meson install -C builddir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

products = [
    LibraryProduct("libxkbfile", :libxkbfile),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    BuildDependency("Xorg_util_macros_jll"),
    Dependency("Xorg_libX11_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# (There are build errors with GCC 4.)
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
