using BinaryBuilder

name = "Glib_Networking"
version = v"2.74.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://download.gnome.org/sources/glib-networking/$(version.major).$(version.minor)/glib-networking-$(version).tar.xz",
                  "1f185aaef094123f8e25d8fa55661b3fd71020163a0174adb35a37685cda613b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glib-networking*/
install_license COPYING
meson --cross-file=${MESON_TARGET_TOOLCHAIN} --libdir lib builddir .
cd builddir/
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgioenvironmentproxy"], :libgioenvironmentproxy, "lib/gio/modules"),
    # LibraryProduct(["libgiognomeproxy"], :libgiognomeproxy, "lib/gio/modules"),  # TODO: maybe add `gsettings-desktop-schemas` dependency later
    # LibraryProduct(["libgiolibproxy"], :libgiolibproxy, "lib/gio/modules"),  # TODO: maybe add `libproxy` dependency later
    LibraryProduct(["libgiognutls"], :libgiognutls, "lib/gio/modules"),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Glib_jll"; compat="$(version.major).$(version.minor)"),
    Dependency("GnuTLS_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
