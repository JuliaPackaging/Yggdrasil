# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gdk_pixbuf"
version = v"2.42.12"

# Collection of sources required to build gdk-pixbuf
sources = [
    ArchiveSource("https://gitlab.gnome.org/GNOME/gdk-pixbuf/-/archive/$(version)/gdk-pixbuf-$(version).tar.bz2",
                  "c608eb59eb3a697de108961c7d64303e5bcd645c2a95da9a9fe60419dfaa56f6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gdk-pixbuf-*/
mkdir build && cd build

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
    HostBuildDependency(PackageSpec(; name="Glib_jll", version=v"2.80.5")),
    Dependency("Glib_jll"; compat="2.80.5"),
    Dependency("JpegTurbo_jll"),
    Dependency("libpng_jll"),
    Dependency("Libtiff_jll"; compat="4.5.1"),
    Dependency("Xorg_libX11_jll"; platforms=linux_freebsd),
    BuildDependency("Xorg_xproto_jll"; platforms=linux_freebsd),
    BuildDependency("Xorg_kbproto_jll"; platforms=linux_freebsd),
    BuildDependency("gobject_introspection_jll"; platforms=introspect_platform)
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"6")
