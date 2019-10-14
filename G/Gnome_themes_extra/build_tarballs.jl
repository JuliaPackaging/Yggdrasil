# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Gnome_themes_extra"
version = v"3.28"

# Collection of sources required to build gnome-themes-extra
sources = [
    "http://ftp.gnome.org/pub/gnome/sources/gnome-themes-extra/$(version.major).$(version.minor)/gnome-themes-extra-$(version.major).$(version.minor).tar.xz" =>
    "7c4ba0bff001f06d8983cfc105adaac42df1d1267a2591798a780bac557a5819",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gnome-themes-extra-*/
apk add intltool

# Clear out `.la` files since they're often wrong and screw us up
rm -f ${prefix}/lib/*.la

FLAGS=()
if [[ "${target}" == *-mingw* ]]; then
    FLAGS+=(ac_cv_path_GTK_UPDATE_ICON_CACHE=gtk-update-icon-cache.exe)
fi

./configure --prefix=${prefix} --host=${target} \
    --disable-gtk2-engine \
    "${FLAGS[@]}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
#platforms = supported_platforms()

# Limit to the same platforms as Gtk for now
platforms = [p for p in supported_platforms() if p isa Union{MacOS,Windows}]

# The products that we will ensure are always built
products = [
    FileProduct("share/themes/Adwaita/index.theme", :adwaita_index),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "GTK3_jll",
    "Librsvg_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
