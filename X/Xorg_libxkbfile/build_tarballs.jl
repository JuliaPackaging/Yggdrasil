# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libxkbfile"
version = v"1.1.3"

# Collection of sources required to build libxkbfile
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libxkbfile-$(version).tar.xz",
                  "a9b63eea997abb9ee6a8b4fbb515831c841f471af845a09de443b28003874bec"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libxkbfile-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
