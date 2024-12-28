# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXi"
version = v"1.8.2"

# Collection of sources required to build libXi
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libXi-$(version).tar.gz",
                  "5542daec66febfeb6f51d57abfa915826efe2e3af57534f4105b82240ea3188d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXi-*/
CPPFLAGS="-I${prefix}/include"
# When compiling for things like ppc64le, we need newer `config.sub` files
update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-malloc0returnsnull=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

products = [
    LibraryProduct("libXi", :libXi),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    BuildDependency("Xorg_util_macros_jll"),
    Dependency("Xorg_libXext_jll"),
    Dependency("Xorg_libXfixes_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
