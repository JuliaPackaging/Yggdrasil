# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "hicolor_icon_theme"
version = v"0.17"

# Collection of sources required to build hicolor_icon_theme
sources = [
    "https://icon-theme.freedesktop.org/releases/hicolor-icon-theme-$(version.major).$(version.minor).tar.xz" =>
    "317484352271d18cbbcfac3868eab798d67fff1b8402e740baa6ff41d588a9d8"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hicolor-icon-theme-*/
./configure --prefix=$prefix --host=$target
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    FileProduct("share/icons/hicolor/index.theme", :hicolor_icon_theme)
    FileProduct("share/icons", :hicolor_icons_dir)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
