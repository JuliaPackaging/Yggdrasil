# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SDL2"
version = v"2.0.10"

# Collection of sources required to build SDL2
sources = [
    "http://www.libsdl.org/release/SDL2-$(version).tar.gz" =>
    "b4656c13a1f0d0023ae2f4a9cf08ec92fffb464e0f24238337784159b8b91d57",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SDL2-*/

FLAGS=()
if [[ "${target}" == *-linux-* ]] || [[ "${target}" == *-freebsd* ]]; then
    FLAGS+=(--with-x)
elif [[ "${target}" == *-mingw* ]]; then
    FLAGS+='libSDL2main_la_LDFLAGS=-no-undefined'
    FLAGS+='libSDL2_test_la_LDFLAGS=-no-undefined'
fi

./configure --prefix=${prefix} --host=${target} \
    --enable-shared \
    --disable-static \
    "${FLAGS[@]}" \
    CPPFLAGS="-I${prefix}/include"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libSDL2", "SDL2"], :libsdl2)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Xorg_libX11_jll",
    "Xorg_libXcursor_jll",
    "Xorg_libXext_jll",
    "Xorg_libXinerama_jll",
    "Xorg_libXrandr_jll",
    "Xorg_libXScrnSaver_jll",
    "Libglvnd_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
