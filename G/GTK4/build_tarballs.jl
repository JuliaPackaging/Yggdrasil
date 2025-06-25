# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GTK4"
version = v"4.19.1"

# Collection of sources required to build GTK
sources = [
    # https://download.gnome.org/sources/gtk/
    ArchiveSource("https://download.gnome.org/sources/gtk/$(version.major).$(version.minor)/gtk-$(version).tar.xz",
                  "7e793899bc2a47fdf52b149b9262f5398a2dd1252cfe58536e3dbfb78848d4eb"),
    FileSource("https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v10.0.0.tar.bz2",
               "ba6b430aed72c63a3768531f6a3ffc2b0fde2c57a3b251450dcf489a894f0894"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gtk*

# We need to run some commands with a native Glib
apk update
apk add glib-dev py3-pip

# we need a newer meson (>= 1.5.0)
pip3 install -U meson

atomic_patch -p1 ../patches/memfd.patch

# This is awful, I know
ln -sf /usr/bin/glib-compile-resources ${bindir}/glib-compile-resources
ln -sf /usr/bin/glib-compile-schemas ${bindir}/glib-compile-schemas
ln -sf /usr/bin/gdk-pixbuf-pixdata ${bindir}/gdk-pixbuf-pixdata

FLAGS=()
if [[ "${target}" == *-apple-* ]]; then
    FLAGS+=(-Dx11-backend=false -Dwayland-backend=false)
elif [[ "${target}" == *-freebsd* ]]; then
    FLAGS+=(-Dwayland-backend=false)
elif [[ "${target}" == *-mingw* ]]; then
    cd $WORKSPACE/srcdir
    tar xjf mingw-w64-v10.0.0.tar.bz2
    cd mingw*/mingw-w64-headers
    ./configure --prefix=/opt/$target/$target/sys-root --enable-sdk=all --host=$target
    make install

    cd ../mingw-w64-crt
    if [ ${target} == "i686-w64-mingw32" ]; then
        _crt_configure_args="--disable-lib64 --enable-lib32"
    elif [ ${target} == "x86_64-w64-mingw32" ]; then
        _crt_configure_args="--disable-lib32 --enable-lib64"
    fi
    ./configure --prefix=/opt/$target/$target/sys-root --enable-sdk=all --host=$target --enable-wildcard ${_crt_configure_args}
    make -j${nproc}
    make install
fi

cd $WORKSPACE/srcdir/gtk*

PKG_CONFIG_SYSROOT_DIR='' meson setup builddir \
    --buildtype=release \
    -Dmedia-gstreamer=disabled \
    -Dintrospection=disabled \
    -Dvulkan=disabled \
    -Dbuild-demos=false \
    -Dbuild-examples=false \
    -Dbuild-tests=false \
    -Dbuild-testsuite=false \
    "${FLAGS[@]}" \
    --cross-file="${MESON_TARGET_TOOLCHAIN}"
meson compile -C builddir
meson install -C builddir

install_license COPYING

# post-install script is disabled when cross-compiling
glib-compile-schemas ${prefix}/share/glib-2.0/schemas

# Remove temporary links
rm ${bindir}/gdk-pixbuf-pixdata ${bindir}/glib-compile-{resources,schemas}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

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
    # Build needs a header from but does not link to libdrm
    BuildDependency("libdrm_jll"; platforms=x11_platforms),
    Dependency("Glib_jll"; compat="2.84.3"),
    Dependency("Graphene_jll"; compat="1.10.8"),
    Dependency("Cairo_jll"; compat="1.18.5"),
    Dependency("Pango_jll"; compat="1.56.3"),
    Dependency("FriBidi_jll"),
    Dependency("FreeType2_jll"; compat="2.13.4"),
    Dependency("gdk_pixbuf_jll"),
    Dependency("Libepoxy_jll"; compat="1.5.11"),
    Dependency("Libtiff_jll"; compat="4.7.1"),
    Dependency("HarfBuzz_jll"),
    Dependency("xkbcommon_jll"; platforms=x11_platforms),
    Dependency("iso_codes_jll"),
    Dependency("Wayland_jll"; platforms=x11_platforms),
    Dependency("Wayland_protocols_jll"; compat="1.44", platforms=x11_platforms),
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
# We need at least GCC 8 to support `__VA_OPT__`
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"8")
