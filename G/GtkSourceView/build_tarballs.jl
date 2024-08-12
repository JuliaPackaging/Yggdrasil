# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GtkSourceView"
version = v"5.10.0"

# Collection of sources required to build GtkSourceView
sources = [
    "https://download.gnome.org/sources/gtksourceview/$(version.major).$(version.minor)/gtksourceview-$(version).tar.xz" =>
    "b38a3010c34f59e13b05175e9d20ca02a3110443fec2b1e5747413801bc9c23f",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gtksourceview-*/

# We need to run native `xmllint` and `glib-compile-resources`
apk add libxml2-utils glib-dev gtk-update-icon-cache

# Don't build broken tests
atomic_patch -p1 ../patches/meson_build_no_tests.patch

# host version needs to be used
rm -f /workspace/destdir/bin/gtk4-update-icon-cache

mkdir build && cd build

MESON_FLAGS=(-Dintrospection=disabled -Dvapi=false)

# buildtype=plain disables stack-protector-strong, needed for this platform
if [[ "${target}" == i686-linux-musl ]]; then
    MESON_FLAGS+=(--buildtype=plain)
fi

meson .. \
    "${MESON_FLAGS[@]}" \
    --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libgtksourceview-5", :libgtksourceview),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Glib_jll", v"2.76.5"; compat="2.76"),
    Dependency("GTK4_jll"),
    Dependency("Cairo_jll"; compat="1.16.1"),
    Dependency("FriBidi_jll"),
    BuildDependency("Xorg_xorgproto_jll"; platforms=filter(p->Sys.islinux(p)||Sys.isfreebsd(p), platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6",preferred_gcc_version=v"5",clang_use_lld=false)
