# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GTK3"
version = v"3.24.29"

# Collection of sources required to build GTK
sources = [
    ArchiveSource("http://ftp.gnome.org/pub/gnome/sources/gtk+/$(version.major).$(version.minor)/gtk+-$(version).tar.xz",
                  "f57ec4ade8f15cab0c23a80dcaee85b876e70a8823d9105f067ce335a8268caa"),
    DirectorySource("./bundled"),
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

# Patch upstreamed: https://gitlab.gnome.org/GNOME/gtk/-/merge_requests/3526
atomic_patch -p1 $WORKSPACE/srcdir/patches/gdkwindow-quartz_c.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/meson_build.patch
# Patch upstreamed: https://gitlab.gnome.org/GNOME/gtk/-/merge_requests/3527
atomic_patch -p1 $WORKSPACE/srcdir/patches/c_standard_c99.patch

FLAGS=()
if [[ "${target}" == *-apple-* ]]; then
    FLAGS+=(-Dx11_backend=false -Dwayland_backend=false)
elif [[ "${target}" == *-freebsd* ]]; then
    FLAGS+=(-Dwayland_backend=false)
fi

if [[ "${target}" == *-mingw* ]]; then
    # Despite what's declared in their meson.build, they require Meson 0.54:
    # https://gitlab.gnome.org/GNOME/gtk/-/issues/3927
    apk add meson --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing
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
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Glib_jll", v"2.59.0"; compat="2.59.0"),
    Dependency("Cairo_jll"),
    Dependency("Pango_jll"),
    Dependency("FriBidi_jll"),
    Dependency("FreeType2_jll"),
    Dependency("gdk_pixbuf_jll"),
    Dependency("Libepoxy_jll"),
    # Gtk 3.24.29 requires ATK 2.35.1
    Dependency("ATK_jll", v"2.36"; compat="2.35.1"),
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
