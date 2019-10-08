# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "HarfBuzz"
version = v"2.6.1"

# Collection of sources required to build Harfbuzz
sources = [
    "https://www.freedesktop.org/software/harfbuzz/release/harfbuzz-$(version).tar.xz" =>
    "c651fb3faaa338aeb280726837c2384064cdc17ef40539228d88a1260960844f",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/harfbuzz-*/
autoreconf -i -f
./configure --prefix=$prefix --host=$target \
    --with-gobject=yes \
    --with-graphite2=yes \
    --with-glib=yes \
    --with-freetype=yes \
    --with-cairo=yes \
    --enable-gtk-doc-html=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libharfbuzz", :libharfbuzz),
    LibraryProduct("libharfbuzz-subset", :libharfbuzz_subset),
    LibraryProduct("libharfbuzz-gobject", :libharfbuzz_gobject),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Graphite2_jll",
    "Libffi_jll",
    "Gettext_jll",
    "Glib_jll",
    "FreeType2_jll",
    "Fontconfig_jll",
    "Cairo_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
