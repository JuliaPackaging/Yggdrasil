# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GTK3"
version = v"3.24.30"

# Collection of sources required to build GTK
sources = [
    ArchiveSource("http://ftp.gnome.org/pub/gnome/sources/gtk+/$(version.major).$(version.minor)/gtk+-$(version).tar.xz",
                  "ba75bfff320ad1f4cfbee92ba813ec336322cc3c660d406aad014b07087a3ba9"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gtk+-*/

# We need to run some commands with a native Glib
apk add glib-dev gtk+3.0

# This is awful, I know
ln -sf /usr/bin/glib-compile-resources ${prefix}/bin/glib-compile-resources
ln -sf /usr/bin/glib-compile-schemas ${prefix}/bin/glib-compile-schemas
ln -sf /usr/bin/gdk-pixbuf-pixdata ${prefix}/bin/gdk-pixbuf-pixdata
# Remove gio-2.0 pkgconfig file so that it isn't picked up by post-install script.
rm ${prefix}/lib/pkgconfig/gio-2.0.pc

atomic_patch -p1 $WORKSPACE/srcdir/patches/meson_build.patch

FLAGS=()
if [[ "${target}" == *-apple-* ]]; then
    FLAGS+=(-Dx11_backend=false -Dwayland_backend=false)
elif [[ "${target}" == *-freebsd* ]]; then
    FLAGS+=(-Dwayland_backend=false)
fi

mkdir build-gtk && cd build-gtk
meson .. \
    -Dintrospection=false \
    -Ddemos=false \
    -Dexamples=false \
    -Dtests=false \
    "${FLAGS[@]}" \
    --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install

# Remove temporary links
rm ${prefix}/bin/gdk-pixbuf-pixdata ${prefix}/bin/glib-compile-{resources,schemas}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libgailutil-3", :libgailutil3),
    LibraryProduct("libgdk-3", :libgdk3),
    LibraryProduct("libgtk-3", :libgtk3),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Need a host Wayland for wayland-scanner
    HostBuildDependency("Wayland_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Glib_jll"; compat="2.68.1"),
    Dependency("Cairo_jll"),
    Dependency("Pango_jll"; compat="1.47.0"),
    Dependency("FriBidi_jll"),
    Dependency("FreeType2_jll"),
    Dependency("gdk_pixbuf_jll"),
    Dependency("Libepoxy_jll"),
    # Gtk 3.24.29 requires ATK 2.35.1
    Dependency("ATK_jll", v"2.36.1"; compat="2.35.1"),
    Dependency("HarfBuzz_jll"),
    Dependency("xkbcommon_jll"),
    Dependency("iso_codes_jll"),
    Dependency("Wayland_jll"),
    Dependency("Xorg_libXrandr_jll"),
    Dependency("Xorg_libX11_jll"),
    Dependency("Xorg_libXrender_jll"),
    Dependency("Xorg_libXi_jll"),
    Dependency("Xorg_libXext_jll"),
    Dependency("Xorg_libXcursor_jll"),
    Dependency("Xorg_libXdamage_jll"),
    Dependency("Xorg_libXfixes_jll"),
    Dependency("Xorg_libXcomposite_jll"),
    Dependency("Xorg_libXinerama_jll"),
    Dependency("Fontconfig_jll"),
    Dependency("at_spi2_atk_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
