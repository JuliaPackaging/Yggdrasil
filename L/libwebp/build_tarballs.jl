# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libwebp"
version = v"1.0.3"

# Collection of sources required to build libwebp
sources = [
    "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-$(version).tar.gz" =>
    "e20a07865c8697bba00aebccc6f54912d6bc333bb4d604e6b07491c1a226b34f",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libwebp-*/
export CFLAGS="-std=c99"
export CPPFLAGS="-I${prefix}/include"
if [[ "${target}" == *-freebsd* ]]; then
    export LDFLAGS="-L${libdir}"
fi
./configure --prefix=$prefix --host=$target \
    --enable-swap-16bit-csp \
    --enable-experimental \
    --enable-libwebp{mux,demux,decoder,extras} \
    --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libwebp", :libwebp),
    LibraryProduct("libwebpdemux", :libwebpdemux),
    LibraryProduct("libwebpmux", :libwebpmux),
    LibraryProduct("libwebpdecoder", :libwebpdecoder),
    LibraryProduct("libwebpmux", :libwebpmux),
    ExecutableProduct("cwebp", :cwebp),
    ExecutableProduct("dwebp", :dwebp),
    ExecutableProduct("gif2webp", :gif2webp),
    ExecutableProduct("img2webp", :img2webp),
    ExecutableProduct("webpinfo", :webpinfo),
    ExecutableProduct("webpmux", :webpmux),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Giflib_jll",
    "JpegTurbo_jll",
    "libpng_jll",
    "Libtiff_jll",
    "Libglvnd_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
