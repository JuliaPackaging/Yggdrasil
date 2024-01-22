# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "gdk_pixbuf"
version = v"2.42.10"

# Collection of sources required to build gdk-pixbuf
sources = [
    ArchiveSource("https://gitlab.gnome.org/GNOME/gdk-pixbuf/-/archive/$(version)/gdk-pixbuf-$(version).tar.bz2",
                  "efb6110873a94bddc2ab09a0e1c81acadaac014d2e622869529e0042c0e81d9b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gdk-pixbuf-*/
mkdir build && cd build

# As seen in the GTK4 build, llvm-ar seems to generate corrupted static archives:
#
#   [119/165] Linking target gdk-pixbuf/pixops/timescale
#   ninja: job failed: [...]
#   ld: warning: ignoring file gdk-pixbuf/pixops/libpixops.a, building for macOS-arm64 but attempting to link with file built for unknown-unsupported file format ( 0x21 0x3C 0x74 0x68 0x69 0x6E 0x3E 0x0A 0x2F 0x20 0x20 0x20 0x20 0x20 0x20 0x20 )
#   Undefined symbols for architecture arm64:
#     "__pixops_composite", referenced from:
#         _main in timescale.c.o
#     "__pixops_composite_color", referenced from:
#         _main in timescale.c.o
#     "__pixops_scale", referenced from:
#         _main in timescale.c.o
#   ld: symbol(s) not found for architecture arm64

if [[ "${target}" == *apple* ]]; then
    sed -i "s?^ar = .*?ar = '/opt/${target}/bin/${target}-ar'?g" "${MESON_TARGET_TOOLCHAIN}"
fi

FLAGS=()
if [[ "${target}" == x86_64-linux-gnu ]]; then
    FLAGS+=(-Dintrospection=enabled)
fi

meson .. \
    -Dman=false \
    -Dinstalled_tests=false \
    -Dgio_sniffing=false \
    "${FLAGS[@]}" \
    --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install

# Cleanup `loaders.cache` file, we're going to generate a new one on the user's machine
find ${prefix}/lib -name loaders.cache -delete
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgdk_pixbuf-2", "libgdk_pixbuf-2.0"], :libgdkpixbuf),
    ExecutableProduct("gdk-pixbuf-query-loaders", :gdk_pixbuf_query_loaders),
    FileProduct("lib/gdk-pixbuf-2.0/2.10.0/loaders", :gdk_pixbuf_loaders_dir),
]

# Some dependencies are needed only on Linux and FreeBSD
linux_freebsd = filter(p->Sys.islinux(p)||Sys.isfreebsd(p), platforms)

# gobject_introspection is needed only on x86_64-linux-gnu
introspect_platform = filter(p -> Sys.islinux(p) && libc(p) == "glibc" && arch(p) == "x86_64", platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    # Need a host gettext for msgfmt
    HostBuildDependency("Gettext_jll"),
    # Need a host glib for glib-compile-resources
    HostBuildDependency("Glib_jll"),
    Dependency("Glib_jll"; compat="2.68.3"),
    Dependency("JpegTurbo_jll"),
    Dependency("libpng_jll"),
    Dependency("Libtiff_jll"; compat="4.5.1"),
    Dependency("Xorg_libX11_jll"; platforms=linux_freebsd),
    BuildDependency("Xorg_xproto_jll"; platforms=linux_freebsd),
    BuildDependency("Xorg_kbproto_jll"; platforms=linux_freebsd),
    BuildDependency("gobject_introspection_jll"; platforms=introspect_platform)
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
