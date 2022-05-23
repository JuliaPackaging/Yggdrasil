# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "gdk_pixbuf"
version = v"2.42.6"

# Collection of sources required to build gdk-pixbuf
sources = [
    ArchiveSource("https://gitlab.gnome.org/GNOME/gdk-pixbuf/-/archive/$(version)/gdk-pixbuf-$(version).tar.bz2",
                  "8a76cffe6a85f2602cf246c1c974eb475aea41c363a932f0c34695fa968f01fd"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gdk-pixbuf-*/
mkdir build && cd build

FLAGS=()
if [[ "${target}" == *-apple-* ]] || [[ "${target}" == *-mingw* ]]; then
    FLAGS+=(-Dx11=false)
fi

meson .. \
    -Dgir=false \
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
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgdk_pixbuf-2", "libgdk_pixbuf-2.0"], :libgdkpixbuf),
    ExecutableProduct("gdk-pixbuf-query-loaders", :gdk_pixbuf_query_loaders),
    FileProduct("lib/gdk-pixbuf-2.0/2.10.0/loaders", :gdk_pixbuf_loaders_dir),
]

# Some dependencies are needed only on Linux and FreeBSD
linux_freebsd = filter(p->Sys.islinux(p)||Sys.isfreebsd(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    # Need a host gettext for msgfmt
    HostBuildDependency("Gettext_jll"),
    # Need a host glib for glib-compile-resources
    HostBuildDependency("Glib_jll"),
    Dependency("Glib_jll"; compat="2.68.1"),
    Dependency("JpegTurbo_jll"),
    Dependency("libpng_jll"),
    Dependency("Libtiff_jll"; compat="4.3.0"),
    Dependency("Xorg_libX11_jll"; platforms=linux_freebsd),
    BuildDependency("Xorg_xproto_jll"; platforms=linux_freebsd),
    BuildDependency("Xorg_kbproto_jll"; platforms=linux_freebsd),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
