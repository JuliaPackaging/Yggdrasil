# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "vtzero"
version = v"1.2.0"

sources = [
    GitSource("https://github.com/mapbox/vtzero.git",
              "c86e378d466950337f203e2dd5ee6aa743cabb3c"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/vtzero

cmake -B build \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release

cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE
"""

platforms = [AnyPlatform()]

products = [
    FileProduct("include/vtzero/vector_tile.hpp", :vector_tile_hpp),
]

dependencies = [
    Dependency("protozero_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version=v"7")
