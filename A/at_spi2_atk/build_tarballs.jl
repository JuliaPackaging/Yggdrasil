# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "at_spi2_atk"
version = v"2.38.0"

# Collection of sources required to build at-spi2-atk
sources = [
    ArchiveSource("http://ftp.gnome.org/pub/gnome/sources/at-spi2-atk/$(version.major).$(version.minor)/at-spi2-atk-$(version).tar.xz",
                  "cfa008a5af822b36ae6287f18182c40c91dd699c55faa38605881ed175ca464f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/at-spi2-atk-*

# We need `fixesproto @6`, but the latest release is `fixesproto @5`.
# (There is a `libXfixes @6`, but no respective `fixesproto @6` exists.)
# The X11 system is quite stable so this work-around should work.
# See e.g. <https://forums.dolphin-emu.org/Thread-compiling-on-ubuntu-20-04-fixesproto-6-0-error>.
mv $libdir/pkgconfig/fixesproto.pc $libdir/pkgconfig/fixesproto.pc.saved
sed 's/Version: 5.0/Version: 6.0/' $libdir/pkgconfig/fixesproto.pc.saved >$libdir/pkgconfig/fixesproto.pc

meson setup builddir --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release -Dtests=false
meson compile -C builddir
meson install -C builddir

# Undo change from above
mv $libdir/pkgconfig/fixesproto.pc.saved $libdir/pkgconfig/fixesproto.pc
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p) || Sys.isfreebsd(p)]

# The products that we will ensure are always built
products = [
    LibraryProduct("libatk-bridge-2.0", :libatk_bridge),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("ATK_jll"),
    # We had to restrict compat with XML2 because of ABI breakage:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/10965#issuecomment-2798501268
    # Updating to `compat="~2.14.1"` is likely possible without problems but requires rebuilding this package
    Dependency("XML2_jll"; compat="~2.13.6"),
    Dependency("Xorg_libX11_jll"),
    Dependency("at_spi2_core_jll"),
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
