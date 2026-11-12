# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gdk_pixbuf"
version = v"2.44.8"

# Collection of sources required to build gdk-pixbuf
sources = [
    ArchiveSource("https://gitlab.gnome.org/GNOME/gdk-pixbuf/-/archive/$(version)/gdk-pixbuf-$(version).tar.bz2",
                  "dac855ad56db6f1ae6af60a46e77d8edce418b4935737a52d42f0f7683cb6e51"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gdk-pixbuf-*
mkdir build && cd build

# Correct pkgconfig entries for host build dependencies, i.e. for
# scripts that need to run at build time. These pkgconfig entries
# would otherwise point to non-existing files, making meson fail.
sed -i 's+glib_genmarshal=${bindir}+'"glib_genmarshal=${host_bindir}"'+' ${host_libdir}/pkgconfig/glib-2.0.pc
sed -i 's+gobject_query=${bindir}+'"gobject_query=${host_bindir}"'+' ${host_libdir}/pkgconfig/glib-2.0.pc
sed -i 's+glib_mkenums=${bindir}+'"glib_mkenums=${host_bindir}"'+' ${host_libdir}/pkgconfig/glib-2.0.pc

# Glycin is a Rust image loading library that is not packaged in Yggdrasil.
# Its option defaults to `auto`, but gdk-pixbuf promotes it to `enabled` on
# Linux, which turns a missing glycin into a hard configure error.
meson .. \
    -Dman=false \
    -Dinstalled_tests=false \
    -Dgio_sniffing=false \
    -Dglycin=disabled \
    -Dpng=enabled \
    -Djpeg=enabled \
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

# Dependencies that must be installed before this package can be built
dependencies = [
    # Need a host gettext for msgfmt
    HostBuildDependency("Gettext_jll"),
    # Need a host glib for glib-compile-resources
    HostBuildDependency(PackageSpec(; name="Glib_jll", version="2.84.0")),
    Dependency("Glib_jll"; compat="2.84.0"),
    Dependency("JpegTurbo_jll"; compat="3.1.1"),
    Dependency("libpng_jll"; compat="1.6.47"),
    Dependency("Libtiff_jll"; compat="4.7.1"),
    Dependency("Xorg_libX11_jll"; platforms=linux_freebsd),
    BuildDependency("Xorg_xproto_jll"; platforms=linux_freebsd),
    BuildDependency("Xorg_kbproto_jll"; platforms=linux_freebsd),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"6")
