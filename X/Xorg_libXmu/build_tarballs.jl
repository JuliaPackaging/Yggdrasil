# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXmu"
version = v"1.1.3"

# Collection of sources required to build libXmu
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libXmu-$(version).tar.bz2",
                  "9c343225e7c3dc0904f2122b562278da5fed639b1b5e880d25111561bac5b731"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXmu-*/
CPPFLAGS="-I${prefix}/include"
# When compiling for things like ppc64le, we need newer `config.sub` files
update_configure_scripts
./configure --prefix=${prefix} --host=${target} --enable-malloc0returnsnull=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if p isa Union{Linux,FreeBSD}]

products = [
    LibraryProduct("libXmu", :libXmu),
    LibraryProduct("libXmuu", :libXmuu),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_kbproto_jll"),
    BuildDependency("Xorg_util_macros_jll"),
    Dependency("Xorg_libXext_jll"),
    Dependency("Xorg_libXt_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
