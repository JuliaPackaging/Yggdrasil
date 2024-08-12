# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GTK4"
version = v"4.12.5"

# Collection of sources required to build GTK
sources = [
    # https://download.gnome.org/sources/gtk/
    ArchiveSource("https://download.gnome.org/sources/gtk/$(version.major).$(version.minor)/gtk-$(version).tar.xz",
                  "28b356d590ee68ef626e2ef9820b2dd21441484a9a042a5a3f0c40e9dfc4f4f8"),
    ArchiveSource("https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v10.0.0.tar.bz2",
                  "ba6b430aed72c63a3768531f6a3ffc2b0fde2c57a3b251450dcf489a894f0894"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gtk*/

# We need to run some commands with a native Glib
apk update
apk add glib-dev

# This is awful, I know
ln -sf /usr/bin/glib-compile-resources ${bindir}/glib-compile-resources
ln -sf /usr/bin/glib-compile-schemas ${bindir}/glib-compile-schemas
ln -sf /usr/bin/gdk-pixbuf-pixdata ${bindir}/gdk-pixbuf-pixdata
# Remove gio-2.0 pkgconfig file so that it isn't picked up by post-install script.
rm ${prefix}/lib/pkgconfig/gio-2.0.pc

FLAGS=()
if [[ "${target}" == *-apple-* ]]; then
    FLAGS+=(-Dx11-backend=false -Dwayland-backend=false)
elif [[ "${target}" == *-freebsd* ]]; then
    FLAGS+=(-Dwayland-backend=false)
elif [[ "${target}" == *-mingw* ]]; then
    cd $WORKSPACE/srcdir/mingw*/mingw-w64-headers
    ./configure --prefix=/opt/$target/$target/sys-root --enable-sdk=all --host=$target
    make install

    cd ../mingw-w64-crt/
    if [ ${target} == "i686-w64-mingw32" ]; then
        _crt_configure_args="--disable-lib64 --enable-lib32"
    elif [ ${target} == "x86_64-w64-mingw32" ]; then
        _crt_configure_args="--disable-lib32 --enable-lib64"
    fi
    ./configure --prefix=/opt/$target/$target/sys-root --enable-sdk=all --host=$target --enable-wildcard ${_crt_configure_args}
    make -j${nproc}
    make install
fi

cd $WORKSPACE/srcdir/gtk*/

mkdir build-gtk && cd build-gtk
meson .. \
    --buildtype=release \
    -Dmedia-gstreamer=disabled \
    -Dintrospection=disabled \
    -Ddemos=false \
    -Dbuild-examples=false \
    -Dbuild-tests=false \
    -Dbuild-testsuite=false \
    -Dgtk_doc=false \
    "${FLAGS[@]}" \
    --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install

install_license ../COPYING

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
    ExecutableProduct("gtk4-builder-tool", :gtk4_builder_tool),
]

x11_platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    # Need a native `sassc`
    HostBuildDependency("SassC_jll"),
    # Need a host Wayland for wayland-scanner
    HostBuildDependency("Wayland_jll"; platforms=x11_platforms),
    BuildDependency("Xorg_xorgproto_jll"; platforms=x11_platforms),
    Dependency("Glib_jll"; compat="2.76.5"),
    Dependency("Graphene_jll"; compat="1.10.6"),
    Dependency("Cairo_jll"),
    Dependency("Pango_jll"; compat="1.50.3"),
    Dependency("FriBidi_jll"),
    Dependency("FreeType2_jll"; compat="2.10.4"),
    Dependency("gdk_pixbuf_jll"),
    Dependency("Libepoxy_jll"),
    Dependency("Libtiff_jll"; compat="4.5.1"),
    Dependency("HarfBuzz_jll"),
    Dependency("xkbcommon_jll"; platforms=x11_platforms),
    Dependency("iso_codes_jll"),
    Dependency("Wayland_jll"; platforms=x11_platforms),
    Dependency("Wayland_protocols_jll"; compat="1.31", platforms=x11_platforms),
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5", clang_use_lld=false)
