# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXrandr"
version = v"1.5.4"
# We bumped the version number to build for riscv64
ygg_version = v"1.5.5"

# Collection of sources required to build libXrandr
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libXrandr-$(version).tar.gz",
                  "c72c94dc3373512ceb67f578952c5d10915b38cc9ebb0fd176a49857b8048e22"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXrandr-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-malloc0returnsnull=yes
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

products = [
    LibraryProduct("libXrandr", :libXrandr),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    BuildDependency("Xorg_util_macros_jll"),
    Dependency("Xorg_libXext_jll"),
    Dependency("Xorg_libXrender_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies; julia_compat="1.6")
