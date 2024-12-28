# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libadwaita"
version = v"1.3.6"

sources = [
    ArchiveSource("https://download.gnome.org/sources/libadwaita/$(version.major).$(version.minor)/libadwaita-$(version).tar.xz",
                  "cb8313dabe78a128415b93891d9aff2aba88ad58e3d5a54562e1f05fc9222979"),
]

# Bash recipe for building across all platforms
script = raw"""

# We need to run some commands with a native Glib
apk add glib-dev

# Copied from GTK4 recipe
ln -sf /usr/bin/glib-compile-resources ${bindir}/glib-compile-resources
ln -sf /usr/bin/glib-compile-schemas ${bindir}/glib-compile-schemas
ln -sf /usr/bin/gdk-pixbuf-pixdata ${bindir}/gdk-pixbuf-pixdata

# oldest version that works, due to use of "@available" macro
export MACOSX_DEPLOYMENT_TARGET=10.14

cd libadwaita*

mkdir build-libadwaita && cd build-libadwaita
meson .. \
    --buildtype=plain \
    -Dintrospection=disabled \
    -Dvapi=false \
    -Dexamples=false \
    -Dtests=false \
    "${FLAGS[@]}" \
    --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install

# Remove gio-2.0 pkgconfig file so that it isn't picked up by post-install script.
rm ${prefix}/lib/pkgconfig/gio-2.0.pc

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
    LibraryProduct("libadwaita-1", :libadwaita),
]

x11_platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"; platforms=x11_platforms),
    Dependency("GTK4_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", clang_use_lld=false)
