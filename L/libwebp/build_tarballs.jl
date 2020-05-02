# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libwebp"
version = v"1.1.0"

# Collection of sources required to build libwebp
sources = [
    ArchiveSource("https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-$(version).tar.gz",
                  "98a052268cc4d5ece27f76572a7f50293f439c17a98e67c4ea0c7ed6f50ef043"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libwebp-*/
export CFLAGS="-std=c99"
export CPPFLAGS="-I${prefix}/include"
if [[ "${target}" == *-freebsd* ]]; then
    export LDFLAGS="-L${libdir}"
fi
./configure --prefix=${prefix} --host=${target} \
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
    LibraryProduct("libwebpdecoder", :libwebpdecoder),
    LibraryProduct("libwebpdemux", :libwebpdemux),
    LibraryProduct("libwebpmux", :libwebpmux),
    LibraryProduct("libwebp", :libwebp),
    ExecutableProduct("cwebp", :cwebp),
    ExecutableProduct("dwebp", :dwebp),
    ExecutableProduct("gif2webp", :gif2webp),
    ExecutableProduct("img2webp", :img2webp),
    ExecutableProduct("webpinfo", :webpinfo),
    ExecutableProduct("webpmux", :webpmux),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Giflib_jll"),
    Dependency("JpegTurbo_jll"),
    Dependency("libpng_jll"),
    Dependency("Libtiff_jll"),
    Dependency("Libglvnd_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
