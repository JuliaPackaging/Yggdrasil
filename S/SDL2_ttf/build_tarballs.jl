# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SDL2_ttf"
version = v"2.24.0"

# Collection of sources required to build SDL2_ttf
sources = [
    GitSource("https://github.com/libsdl-org/SDL_ttf.git",
              "2a891473eaf05ba1707a4b7913e6c4db7de7458a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SDL_ttf

mkdir build && cd build

cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DSDL2TTF_SAMPLES=OFF \
      -DSDL2TTF_HARFBUZZ=OFF \
      -DSDL2TTF_VENDORED=OFF ..
make -j${nproc}
make install
install_license ../LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libSDL2_ttf", "SDL2_ttf"], :libsdl2_ttf),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("FreeType2_jll"; compat="2.13.4"),
    Dependency("SDL2_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
