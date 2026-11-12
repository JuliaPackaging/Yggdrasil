# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXcomposite"
version = v"0.4.7"

# Collection of sources required to build libXcomposite
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libXcomposite-$(version).tar.xz",
                  "8bdf310967f484503fa51714cf97bff0723d9b673e0eecbf92b3f97c060c8ccb"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXcomposite-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-static=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

products = [
    LibraryProduct("libXcomposite", :libXcomposite),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    BuildDependency("Xorg_util_macros_jll"),
    Dependency("Xorg_libXfixes_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
