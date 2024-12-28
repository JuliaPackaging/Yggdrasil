# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xcb_util_cursor"
version = v"0.1.4"

# Collection of sources required to build libxcb
sources = [
    ArchiveSource("https://xcb.freedesktop.org/dist/xcb-util-cursor-$(version).tar.xz",
                  "28dcfe90bcab7b3561abe0dd58eb6832aa9cc77cfe42fcdfa4ebe20d605231fb"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xcb-util-cursor-*/
CPPFLAGS="-I${prefix}/include"

# When compiling for things like ppc64le, we need newer `config.sub` files
update_configure_scripts

# I don't know how to deal with .la files and I'm not afraid to show it
sed "s/image/render/g" $prefix/lib/libxcb-image.la  > $prefix/lib/libxcb-render.la
sed "s/image/shm/g" $prefix/lib/libxcb-image.la  > $prefix/lib/libxcb-shm.la
sed "s/-image//g" $prefix/lib/libxcb-image.la  > $prefix/lib/libxcb.la
sed "s/xcb-image/Xau/g" $prefix/lib/libxcb-image.la  > $prefix/lib/libXau.la
sed "s/xcb-image/Xdmcp/g" $prefix/lib/libxcb-image.la  > $prefix/lib/libXdmcp.la

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if arch(p) != "armv6l" && (Sys.islinux(p) || Sys.isfreebsd(p))]

products = [
    LibraryProduct("libxcb-cursor", :libxcb_cursor),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    BuildDependency("Xorg_util_macros_jll"),
    Dependency("Xorg_xcb_util_jll"),
    Dependency("Xorg_xcb_util_image_jll"),
    Dependency("Xorg_xcb_util_renderutil_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
