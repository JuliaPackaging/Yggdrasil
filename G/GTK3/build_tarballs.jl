# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GTK3"
version = v"3.24.11"

# Collection of sources required to build GTK
sources = [
    "http://ftp.gnome.org/pub/gnome/sources/gtk+/$(version.major).$(version.minor)/gtk+-$(version).tar.xz" =>
    "dba7658d0a2e1bfad8260f5210ca02988f233d1d86edacb95eceed7eca982895",
    "./bundled"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gtk+-*/

# We need to run some commands with a native Glib
apk add glib-dev gtk+3.0

if [[ "${target}" == *-linux-* ]]; then
    # We need to run `wayland-scanner` on the build system only when Wayland is
    # available, i.e. only on Linux
    apk add wayland-dev
fi

# This is awful, I know
ln -sf /usr/bin/glib-compile-resources ${prefix}/bin/glib-compile-resources
ln -sf /usr/bin/glib-compile-schemas ${prefix}/bin/glib-compile-schemas
ln -sf /usr/bin/gdk-pixbuf-pixdata ${prefix}/bin/gdk-pixbuf-pixdata
# Remove wayland-scanner when present, so that we can call the native one
rm -f ${prefix}/bin/wayland-scanner

atomic_patch -p1 $WORKSPACE/srcdir/patches/gdkwindow-quartz_c.patch
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
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libgailutil-3", :libgailutil3),
    LibraryProduct("libgdk-3", :libgdk3),
    LibraryProduct("libgtk-3", :libgtk3),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Glib_jll",
    "Cairo_jll",
    "Pango_jll",
    "FriBidi_jll",
    "FreeType2_jll",
    "gdk_pixbuf_jll",
    "Libepoxy_jll",
    "ATK_jll",
    "HarfBuzz_jll",
    "xkbcommon_jll",
    "iso_codes_jll",
    "Wayland_jll",
    "Xorg_libXrandr_jll",
    "Xorg_libX11_jll",
    "Xorg_libXrender_jll",
    "Xorg_libXi_jll",
    "Xorg_libXext_jll",
    "Xorg_libXcursor_jll",
    "Xorg_libXdamage_jll",
    "Xorg_libXfixes_jll",
    "Xorg_libXcomposite_jll",
    "Xorg_libXinerama_jll",
    "Fontconfig_jll",
    "at_spi2_atk_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
