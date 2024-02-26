# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "adwaita_icon_theme"
version = v"43.0.1"

# Collection of sources required to build adwaita-icon-theme
sources = [
    ArchiveSource("https://download.gnome.org/sources/adwaita-icon-theme/$(version.major)/adwaita-icon-theme-$(version.major).tar.xz",
                  "2e3ac77d32a6aa5554155df37e8f0a0dd54fc5a65fd721e88d505f970da32ec6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/adwaita-icon-theme-*/

# Install native gtk+3.0 so that we get `gtk-encode-symbolic-svg`
apk add gtk+3.0 librsvg
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    FileProduct("share/icons", :adwaita_icons_dir),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("hicolor_icon_theme_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
