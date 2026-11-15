# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xcb_util_wm"
version = v"0.4.2"

# Collection of sources required to build libxcb
sources = [
    ArchiveSource("https://xcb.freedesktop.org/dist/xcb-util-wm-$(version).tar.xz",
                  "62c34e21d06264687faea7edbf63632c9f04d55e72114aa4a57bb95e4f888a0b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xcb-util-wm-*/

# When compiling for things like ppc64le, we need newer `config.sub` files
update_configure_scripts

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-malloc0returnsnull=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p->!(Sys.islinux(p) || Sys.isfreebsd(p)))

products = [
    LibraryProduct("libxcb-ewmh", :libxcb_ewmh),
    LibraryProduct("libxcb-icccm", :libxcb_icccm),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Xorg_xcb_util_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
