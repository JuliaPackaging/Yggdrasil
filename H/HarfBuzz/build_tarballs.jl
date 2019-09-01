# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "HarfBuzz"
version = v"2.6.1"

# Collection of sources required to build Harfbuzz
sources = [
    "https://www.freedesktop.org/software/harfbuzz/release/harfbuzz-$(version).tar.xz" =>
    "c651fb3faaa338aeb280726837c2384064cdc17ef40539228d88a1260960844f",
    "./bundled"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/harfbuzz-*/
atomic_patch -p1 ../patches/config_ac-freetype2_version.patch
autoreconf
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
platforms = [p for p in supported_platforms() if !(p isa Union{MacOS,Windows})]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libharfbuzz", :libharfbuzz),
    LibraryProduct(prefix, "libharfbuzz-subset", :libharfbuzz_subset),
    LibraryProduct(prefix, "libharfbuzz-gobject", :libharfbuzz_gobject),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Graphite2
    "https://github.com/giordano/Yggdrasil/releases/download/Graphite2-v1.3.13/build_Graphite2.v1.3.13.jl",
    # Libffi
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Libffi-v3.2.1-0/build_Libffi.v3.2.1.jl",
    # Gettext-related dependencies
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Libiconv-v1.15-0/build_Libiconv.v1.15.0.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Gettext-v0.19.8-0/build_Gettext.v0.19.8.jl",
    # Glib-related dependencies
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/PCRE-v8.42-2/build_PCRE.v8.42.0.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Glib-v2.59.0%2B0/build_Glib.v2.59.0.jl",
    # Freetype2-related dependencies
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Bzip2-v1.0.6-2/build_Bzip2.v1.0.6.jl",
    "https://github.com/JuliaGraphics/FreeTypeBuilder/releases/download/v2.9.1-4/build_FreeType2.v2.10.0.jl",
    # Fontconfig-related dependencies
    "https://github.com/giordano/Yggdrasil/releases/download/Cairo-v1.14.12/build_Libuuid.v2.34.0.jl",
    "https://github.com/giordano/Yggdrasil/releases/download/Cairo-v1.14.12/build_Expat.v2.2.7.jl",
    "https://github.com/giordano/Yggdrasil/releases/download/Cairo-v1.14.12/build_Fontconfig.v2.13.1.jl",
    # Cairo-related dependencies
    "https://github.com/giordano/Yggdrasil/releases/download/Cairo-v1.14.12/build_X11.v1.6.8.jl",
    "https://github.com/giordano/Yggdrasil/releases/download/Cairo-v1.14.12/build_LZO.v2.10.0.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Pixman-v0.36.0-0/build_Pixman.v0.36.0.jl",
    "https://github.com/JuliaIO/LibpngBuilder/releases/download/v1.0.3/build_libpng.v1.6.37.jl",
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.4/build_Zlib.v1.2.11.jl",
    "https://github.com/giordano/Yggdrasil/releases/download/Cairo-v1.14.12/build_Cairo.v1.14.12.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
