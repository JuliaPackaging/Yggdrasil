# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SDL2_ttf"
version = v"2.0.15"

# Collection of sources required to build SDL2_ttf
sources = [
    "https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-$(version).tar.gz" =>
    "a9eceb1ad88c1f1545cd7bd28e7cbc0b2c14191d40238f531a15b01b1b22cd33",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SDL2_ttf-*/

FLAGS=()
if [[ "${target}" == *-linux-* ]] || [[ "${target}" == *-freebsd* ]]; then
    FLAGS+=(--with-x)
fi

atomic_patch -p1 ../patches/configure_in-v2.0.15.patch
touch NEWS README AUTHORS ChangeLog
# For some reasons, the first time `autoreconf` may fail,
# but with some encouragement it can do it
autoreconf -vi || autoreconf -vi
export CPPFLAGS="-I${prefix}/include/SDL2"
./configure --prefix=${prefix} --host=${target} \
    --enable-shared \
    --disable-static \
    "${FLAGS[@]}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libSDL2_ttf", "SDL2_ttf"], :libsdl2_ttf)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "SDL2_jll",
    "FreeType2_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
