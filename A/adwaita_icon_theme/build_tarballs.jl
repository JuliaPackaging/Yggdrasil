# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "adwaita_icon_theme"
version = v"3.33.92"

# Collection of sources required to build adwaita-icon-theme
sources = [
    ArchiveSource("https://gitlab.gnome.org/GNOME/adwaita-icon-theme/-/archive/$(version)/adwaita-icon-theme-$(version).tar.bz2",
                  "9e2078bf9e4d28f2a921fa88159733fe83a1fd37f8cbd768a5de3b83f44f0973"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/adwaita-icon-theme-*/

# Install native gtk+3.0 so that we get `gtk-encode-symbolic-svg`
apk add gtk+3.0 librsvg
./autogen.sh --prefix=$prefix --host=$target
./configure --prefix=$prefix --host=$target
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = Product[
    FileProduct("share/icons", :adwaita_icons_dir),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("hicolor_icon_theme_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
