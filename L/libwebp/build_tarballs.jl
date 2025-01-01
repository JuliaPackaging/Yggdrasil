# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libwebp"
version = v"1.5.0"

# Collection of sources required to build libwebp
sources = [
    GitSource("https://chromium.googlesource.com/webm/libwebp",
              "f7710292e894c8413edaca4610d11dde843c04fd"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libwebp
export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"
./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
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
    Dependency("Libtiff_jll"; compat="4.7.1"),
    Dependency("Libglvnd_jll"; platforms=filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We need at least GCC 10 for aarch64-linux-gnu
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10")
