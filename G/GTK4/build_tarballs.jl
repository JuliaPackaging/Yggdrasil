# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GTK4"
version = v"4.6.0"

# Collection of sources required to build GTK
sources = [
    GitSource("https://gitlab.gnome.org/GNOME/gtk.git",
              "70cb61fb7104c76a15bc6494a10e6ff1d470f6d8"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gtk*/

# We need to run some commands with a native Glib
apk add glib-dev gtk4.0 sassc

# Apparently this is the quickest way to get gi-docgen
pip3 install gi-docgen

# This is awful, I know
ln -sf /usr/bin/glib-compile-resources ${prefix}/bin/glib-compile-resources
ln -sf /usr/bin/glib-compile-schemas ${prefix}/bin/glib-compile-schemas
ln -sf /usr/bin/gdk-pixbuf-pixdata ${prefix}/bin/gdk-pixbuf-pixdata
# Remove gio-2.0 pkgconfig file so that it isn't picked up by post-install script.
rm ${prefix}/lib/pkgconfig/gio-2.0.pc

# # Meson fails to find wayland-scanner with pkg-config and cmake, while trying to prepare
# # tests... that we didn't ask in the first place:
# # https://gitlab.gnome.org/GNOME/gtk/-/issues/4472
# atomic_patch -p1 $WORKSPACE/srcdir/patches/wayland-protocols-no-tests.patch

FLAGS=()
if [[ "${target}" == *-apple-* ]]; then
    FLAGS+=(-Dx11-backend=false -Dwayland-backend=false)
elif [[ "${target}" == *-freebsd* ]]; then
    FLAGS+=(-Dwayland-backend=false)
elif [[ "${target}" == *-mingw* ]]; then
    # Need to tell we're targeting at least Windows 7 so that `GC_ALLGESTURES` is defined
    sed -ri "s/^c_args = \[(.*)\]/c_args = [\1, '-DWINVER=_WIN32_WINNT_WIN7']/" ${MESON_TARGET_TOOLCHAIN}
fi

mkdir build-gtk && cd build-gtk
meson .. \
    -Dmedia-gstreamer=disabled \
    -Dintrospection=disabled \
    -Ddemos=false \
    -Dbuild-examples=false \
    -Dbuild-tests=false \
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
    # LibraryProduct("libgailutil-3", :libgailutil3),
    # LibraryProduct("libgdk-3", :libgdk3),
    # LibraryProduct("libgtk-3", :libgtk3),
]

x11_platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    # Need a host Wayland for wayland-scanner
    HostBuildDependency("Wayland_jll"; platforms=x11_platforms),
    BuildDependency("Xorg_xorgproto_jll"; platforms=x11_platforms),
    Dependency("Glib_jll"; compat="2.68.3"),
    Dependency("Graphene_jll"; compat="1.10.6"),
    Dependency("Cairo_jll"),
    Dependency("Pango_jll"; compat="1.47.0"),
    Dependency("FriBidi_jll"),
    Dependency("FreeType2_jll"),
    Dependency("gdk_pixbuf_jll"),
    Dependency("Libepoxy_jll"),
    # Gtk 3.24.29 requires ATK 2.35.1
    # Dependency("ATK_jll", v"2.36.1"; compat="2.35.1"),
    Dependency("HarfBuzz_jll"),
    Dependency("xkbcommon_jll"; platforms=x11_platforms),
    Dependency("iso_codes_jll"),
    Dependency("Wayland_jll"; platforms=x11_platforms),
    Dependency("Wayland_protocols_jll"; compat="1.23", platforms=x11_platforms),
    Dependency("Xorg_libXrandr_jll"; platforms=x11_platforms),
    Dependency("Xorg_libX11_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXrender_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXi_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXext_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXcursor_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXdamage_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXfixes_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXcomposite_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXinerama_jll"; platforms=x11_platforms),
    Dependency("Fontconfig_jll"),
    # Dependency("at_spi2_atk_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")
