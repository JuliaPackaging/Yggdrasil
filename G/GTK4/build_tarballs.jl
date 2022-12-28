# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GTK4"
version = v"4.6.9"

# Collection of sources required to build GTK
sources = [
    # https://download.gnome.org/sources/gtk/
    ArchiveSource("https://download.gnome.org/sources/gtk/$(version.major).$(version.minor)/gtk-$(version).tar.xz",
                  "decad346d6a94141ab667c43483e7a4b97c7969c23d589dd63cd6a49498a43d0"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gtk*/

# We need to run some commands with a native Glib
apk add glib-dev

# This is awful, I know
ln -sf /usr/bin/glib-compile-resources ${bindir}/glib-compile-resources
ln -sf /usr/bin/glib-compile-schemas ${bindir}/glib-compile-schemas
ln -sf /usr/bin/gdk-pixbuf-pixdata ${bindir}/gdk-pixbuf-pixdata
# Remove gio-2.0 pkgconfig file so that it isn't picked up by post-install script.
rm ${prefix}/lib/pkgconfig/gio-2.0.pc

# llvm-ar seems to generate corrupted static archives:
#
#     [974/980] Linking target gtk/libgtk-4.1.dylib
#     ninja: job failed: [...]
#     ld: warning: ignoring file gtk/css/libgtk_css.a, building for macOS-x86_64 but attempting to link with file built for unknown-unsupported file format ( 0x21 0x3C 0x74 0x68 0x69 0x6E 0x3E 0x0A 0x2F 0x20 0x20 0x20 0x20 0x20 0x20 0x20 )
#     ld: warning: ignoring file gtk/libgtk.a, building for macOS-x86_64 but attempting to link with file built for unknown-unsupported file format ( 0x21 0x3C 0x74 0x68 0x69 0x6E 0x3E 0x0A 0x2F 0x20 0x20 0x20 0x20 0x20 0x20 0x20 )
#     ld: warning: ignoring file gsk/libgsk.a, building for macOS-x86_64 but attempting to link with file built for unknown-unsupported file format ( 0x21 0x3C 0x74 0x68 0x69 0x6E 0x3E 0x0A 0x2F 0x20 0x20 0x20 0x20 0x20 0x20 0x20 )
#     ld: warning: ignoring file gsk/libgsk_f16c.a, building for macOS-x86_64 but attempting to link with file built for unknown-unsupported file format ( 0x21 0x3C 0x74 0x68 0x69 0x6E 0x3E 0x0A 0x2F 0x20 0x20 0x20 0x20 0x20 0x20 0x20 )
#     Undefined symbols for architecture x86_64:
#       "_gtk_make_symbolic_pixbuf_from_data", referenced from:
#           _main in encodesymbolic.c.o
#     ld: symbol(s) not found for architecture x86_64
if [[ "${target}" == *apple* ]]; then
    sed -i "s?^ar = .*?ar = '/opt/${target}/bin/${target}-ar'?g" "${MESON_TARGET_TOOLCHAIN}"
fi

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
    --buildtype=release \
    -Dmedia-gstreamer=disabled \
    -Dintrospection=disabled \
    -Ddemos=false \
    -Dbuild-examples=false \
    -Dbuild-tests=false \
    -Dgtk_doc=false \
    "${FLAGS[@]}" \
    --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install

# post-install script is disabled when cross-compiling
glib-compile-schemas ${prefix}/share/glib-2.0/schemas

# Remove temporary links
rm ${bindir}/gdk-pixbuf-pixdata ${bindir}/glib-compile-{resources,schemas}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libgtk-4", :libgtk4),
]

x11_platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    # Need a native `sassc`
    HostBuildDependency("SassC_jll"),
    # Need a host Wayland for wayland-scanner
    HostBuildDependency("Wayland_jll"; platforms=x11_platforms),
    BuildDependency("Xorg_xorgproto_jll"; platforms=x11_platforms),
    Dependency("Glib_jll"; compat="2.68.3"),
    Dependency("Graphene_jll"; compat="1.10.6"),
    Dependency("Cairo_jll"),
    Dependency("Pango_jll"; compat="1.50.3"),
    Dependency("FriBidi_jll"),
    Dependency("FreeType2_jll"),
    Dependency("gdk_pixbuf_jll"),
    Dependency("Libepoxy_jll"),
    Dependency("HarfBuzz_jll"),
    Dependency("xkbcommon_jll"; platforms=x11_platforms),
    Dependency("iso_codes_jll"),
    Dependency("Wayland_jll"; platforms=x11_platforms),
    Dependency("Wayland_protocols_jll"; compat="1.25", platforms=x11_platforms),
    Dependency("Xorg_libXrandr_jll"; platforms=x11_platforms),
    Dependency("Xorg_libX11_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXrender_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXi_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXext_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXcursor_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXdamage_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXfixes_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXinerama_jll"; platforms=x11_platforms),
    Dependency("Fontconfig_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")
