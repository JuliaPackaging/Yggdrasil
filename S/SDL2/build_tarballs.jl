# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SDL2"
version = v"2.0.10"

# Collection of sources required to build SDL2
sources = [
    "http://www.libsdl.org/release/SDL2-2.0.10.tar.gz" =>
    "b4656c13a1f0d0023ae2f4a9cf08ec92fffb464e0f24238337784159b8b91d57",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SDL2-*
mkdir -p build
cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DSDL_STATIC=OFF \
    -DSDL_DLOPEN=ON \
    -DARTS=OFF \
    -DESD=OFF \
    -DNAS=OFF \
    -DALSA=ON \
    -DPULSEAUDIO_SHARED=ON \
    -DVIDEO_WAYLAND=ON \
    -DRPATH=OFF \
    -DCLOCK_GETTIME=ON \
    -DJACK_SHARED=ON
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    Windows(:i686),
    Windows(:x86_64)
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libSDL2", :libsdl2)
]

# Dependencies that must be installed before this package can be built
dependencies = [

]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
