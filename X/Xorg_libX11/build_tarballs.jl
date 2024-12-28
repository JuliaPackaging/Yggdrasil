# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libX11"
version = v"1.8.6"

# Collection of sources required to build libX11
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libX11-$(version).tar.xz",
                  "59535b7cc6989ba806a022f7e8533b28c4397b9d86e9d07b6df0c0703fa25cc9"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libX11-*/
CPPFLAGS="-I${prefix}/include"
# When compiling for things like ppc64le, we need newer `config.sub` files
update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-malloc0returnsnull=no
# For some obscure reason, this Makefile may not get the value of CPPFLAGS
sed -i "s?CPPFLAGS = ?CPPFLAGS = ${CPPFLAGS}?" src/util/Makefile
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p->!(Sys.islinux(p) || Sys.isfreebsd(p)))


products = [
    LibraryProduct("libX11", :libX11),
    LibraryProduct("libX11-xcb", :libX11_xcb),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    BuildDependency("Xorg_util_macros_jll"),
    Dependency("Xorg_libxcb_jll"),
    Dependency("Xorg_xtrans_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
# Build trigger: 1
