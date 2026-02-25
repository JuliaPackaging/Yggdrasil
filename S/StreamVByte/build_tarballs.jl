using BinaryBuilder

name = "StreamVByte"
version = v"2.0.0"

sources = [
    GitSource("https://github.com/fast-pack/streamvbyte.git",
              "f27641e3194d14d667e30928a418685d943ab62c")
]

script = raw"""
cd ${WORKSPACE}/srcdir/streamvbyte*

mkdir build
cmake \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -B build
cmake --build build
cmake --install build
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libstreamvbyte", :libstreamvbyte),
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
