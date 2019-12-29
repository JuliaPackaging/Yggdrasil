# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GtkSourceView"
version = v"4.4.0"

# Collection of sources required to build GtkSourceView
sources = [
    "https://download.gnome.org/sources/gtksourceview/4.4/gtksourceview-$(version).tar.xz" =>
    "9ddb914aef70a29a66acd93b4f762d5681202e44094d2d6370e51c9e389e689a",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gtksourceview-*/

# We need to run native `xmllint` and `glib-compile-resources`
apk add libxml2-utils glib-dev

mkdir build && cd build
meson .. \
    -Dgir=false \
    --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgtksourceview-4", :libgtksourceview),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Glib_jll",
    "GTK3_jll",
    "FriBidi_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
