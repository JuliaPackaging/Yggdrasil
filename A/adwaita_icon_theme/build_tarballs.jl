# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "adwaita_icon_theme"
version = v"3.33.92"

# Collection of sources required to build adwaita-icon-theme
sources = [
    "https://gitlab.gnome.org/GNOME/adwaita-icon-theme/-/archive/$(version)/adwaita-icon-theme-$(version).tar.bz2" =>
    "9e2078bf9e4d28f2a921fa88159733fe83a1fd37f8cbd768a5de3b83f44f0973"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/adwaita-icon-theme-*/
./autogen.sh --prefix=$prefix --host=$target
./configure --prefix=$prefix --host=$target
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    FileProduct("share/icons", :icons_dir),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
