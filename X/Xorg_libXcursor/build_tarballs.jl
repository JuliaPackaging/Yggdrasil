# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXcursor"
version = v"1.2.0"

# Collection of sources required to build libXcursor
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libXcursor-$(version).tar.bz2",
                  "3ad3e9f8251094af6fe8cb4afcf63e28df504d46bfa5a5529db74a505d628782"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXcursor-*/
CPPFLAGS="-I${prefix}/include"
# When compiling for things like ppc64le, we need newer `config.sub` files
update_configure_scripts
./configure --prefix=${prefix} --host=${target} --enable-malloc0returnsnull=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

products = [
    LibraryProduct("libXcursor", :libXcursor),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    BuildDependency("Xorg_util_macros_jll"),
    Dependency("Xorg_libXfixes_jll"),
    Dependency("Xorg_libXrender_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

