# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "hicolor_icon_theme"
version = v"0.18"

# Collection of sources required to build hicolor_icon_theme
sources = [
    ArchiveSource("https://icon-theme.freedesktop.org/releases/hicolor-icon-theme-$(version.major).$(version.minor).tar.xz",
                  "db0e50a80aa3bf64bb45cbca5cf9f75efd9348cf2ac690b907435238c3cf81d7"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hicolor-icon-theme-*/
meson setup build --prefix=${prefix}
meson install -C build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("share/icons/hicolor/index.theme", :hicolor_icon_theme)
    FileProduct("share/icons", :hicolor_icons_dir)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
