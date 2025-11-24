# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xcb_util_image"
version = v"0.4.1"

# Collection of sources required to build libxcb
sources = [
    ArchiveSource("https://xcb.freedesktop.org/dist/xcb-util-image-$(version).tar.xz",
                  "ccad8ee5dadb1271fd4727ad14d9bd77a64e505608766c4e98267d9aede40d3d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xcb-util-image-*/

# When compiling for things like ppc64le, we need newer `config.sub` files
update_configure_scripts

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --enable-malloc0returnsnull=no \
    --with-pic
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

products = [
    LibraryProduct("libxcb-image", :libxcb_image),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Xorg_xcb_util_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
