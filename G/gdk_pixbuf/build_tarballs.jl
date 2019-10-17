# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "gdk_pixbuf"
version = v"2.38.2" # we are actually on master

# Collection of sources required to build gdk-pixbuf
sources = [
    "https://gitlab.gnome.org/GNOME/gdk-pixbuf/-/archive/3c7740498fd31b6746dd7e04601886766a6644b7/gdk-pixbuf-3c7740498fd31b6746dd7e04601886766a6644b7.tar.bz2" =>
    "9fad057e8c51bc4373948a02c8ee7d8afe254b361fb4abc43767fce43982dd25"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gdk-pixbuf-*/
mkdir build && cd build

# Get a local gettext for msgfmt cross-building
apk add gettext

FLAGS=()
if [[ "${target}" == *-apple-* ]] || [[ "${target}" == *-mingw* ]]; then
    FLAGS+=(-Dx11=false)
fi

meson .. \
    -Dgir=false \
    -Dman=false \
    -Dinstalled_tests=false \
    -Dgio_sniffing=false \
    "${FLAGS[@]}" \
    --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install

# Cleanup `loaders.cache` file, we're going to generate a new one on the user's machine
rm -f ${prefix}/lib/gdk-pixbuf-2.0/2.10.0/loaders/loaders.cache
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgdk_pixbuf-2", "libgdk_pixbuf-2.0"], :libgdkpixbuf),
    ExecutableProduct("gdk-pixbuf-query-loaders", :gdk_pixbuf_query_loaders),
    FileProduct("lib/gdk-pixbuf-2.0/2.10.0/loaders", :gdk_pixbuf_loaders_dir),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Glib_jll",
    "JpegTurbo_jll",
    "libpng_jll",
    "Libtiff_jll",
    "X11_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
