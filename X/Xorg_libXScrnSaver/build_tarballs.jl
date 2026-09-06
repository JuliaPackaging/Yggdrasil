# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXScrnSaver"
version = v"1.2.5"

# Collection of sources required to build libXScrnSaver
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libXScrnSaver-$(version).tar.xz",
                  "5057365f847253e0e275871441e10ff7846c8322a5d88e1e187d326de1cd8d00"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXScrnSaver-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-malloc0returnsnull=no --enable-static=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

products = [
    LibraryProduct("libXss", :libXScrnSaver),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_util_macros_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Xorg_libXext_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
