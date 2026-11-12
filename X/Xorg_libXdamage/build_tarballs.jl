# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXdamage"
version = v"1.1.7"

# Collection of sources required to build libXdamage
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libXdamage-$(version).tar.xz",
                  "127067f521d3ee467b97bcb145aeba1078e2454d448e8748eb984d5b397bde24"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXdamage-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-static=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

products = [
    LibraryProduct("libXdamage", :libXdamage),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Xorg_libXfixes_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
