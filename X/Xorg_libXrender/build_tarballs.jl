# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXrender"
version = v"0.9.11"

# Collection of sources required to build libXrender
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libXrender-$(version).tar.xz",
                  "bc53759a3a83d1ff702fb59641b3d2f7c56e05051fa0cfa93501166fa782dc24"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXrender-*/
# When compiling for things like ppc64le, we need newer `config.sub` files
update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-malloc0returnsnull=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p->Sys.isapple(p) || Sys.iswindows(p))

products = [
    LibraryProduct("libXrender", :libXrender),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Xorg_libX11_jll"; compat="1.8.6"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
# Build trigger: 1
