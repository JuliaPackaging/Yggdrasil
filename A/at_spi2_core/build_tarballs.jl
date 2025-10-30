# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "at_spi2_core"
version = v"2.58.1"

# Collection of sources required to build at-spi2-core
sources = [
    ArchiveSource("http://ftp.gnome.org/pub/gnome/sources/at-spi2-core/$(version.major).$(version.minor)/at-spi2-core-$(version).tar.xz",
                  "7f374a6a38cd70ff4b32c9d3a0310bfa804d946fed4c9e69a7d49facdcb95e9c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/at-spi2-core-*

mkdir build && cd build

# Get a local gettext for msgfmt cross-building
apk add gettext

# We need `fixesproto @6`, but the latest release is `fixesproto @5`.
# (There is a `libXfixes @6`, but no respective `fixesproto @6` exists.)
# The X11 system is quite stable so this work-around should work.
# See e.g. <https://forums.dolphin-emu.org/Thread-compiling-on-ubuntu-20-04-fixesproto-6-0-error>.
mv $libdir/pkgconfig/fixesproto.pc $libdir/pkgconfig/fixesproto.pc.saved
sed 's/Version: 5.0/Version: 6.0/' $libdir/pkgconfig/fixesproto.pc.saved >$libdir/pkgconfig/fixesproto.pc

meson .. --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Dintrospection=disabled \
    -Dx11=enabled \
    -Dsystemd_user_dir=no
ninja -j${nproc}
ninja install

# Undo change from above
mv $libdir/pkgconfig/fixesproto.pc.saved $libdir/pkgconfig/fixesproto.pc
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

# The products that we will ensure are always built
products = [
    LibraryProduct("libatspi", :libatspi),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Dbus_jll"),
    Dependency("Glib_jll"; compat="2.84.0"),
    Dependency("Xorg_libXtst_jll"),
    BuildDependency("Xorg_fixesproto_jll"),
    BuildDependency("Xorg_inputproto_jll"),
    BuildDependency("Xorg_kbproto_jll"),
    BuildDependency("Xorg_recordproto_jll"),
    BuildDependency("Xorg_xextproto_jll"),
    BuildDependency("Xorg_xproto_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
