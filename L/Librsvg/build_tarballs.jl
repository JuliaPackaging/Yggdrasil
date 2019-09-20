# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Librsvg"
version = v"2.42"

# Collection of sources required to build librsvg
sources = [
    "https://download.gnome.org/sources/librsvg/$(version.major).$(version.minor)/librsvg-$(version).tar.xz" =>
    "9ab0a728b2d9e6edc561bf35d65054480aee28b278c18b6eb6d0a41a1604461a"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/librsvg-*/

FLAGS=()
if [[ "${target}" == *-apple-* ]]; then
    # We purposefully use an old binutils, so we must disable -Bsymbolic
    FLAGS+=(--disable-Bsymbolic)
fi

./configure --prefix=$prefix --host=$target \
    --disable-static \
    --enable-pixbuf-loader \
    --disable-introspection \
    --disable-gtk-doc-html \
    "${FLAGS[@]}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("librsvg-2", :libgdkpixbuf),
    LibraryProduct("libpixbufloader-svg", :libpixbufloader_svg),
    ExecutableProduct("rsvg-convert", :rsvg_convert),
    ExecutableProduct("rsvg-view-3", :rsvg_view),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "gdk_pixbuf_jll",
    "Pango_jll",
    "Libcroco_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust])
