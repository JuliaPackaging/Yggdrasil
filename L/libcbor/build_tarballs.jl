using BinaryBuilder

name = "libcbor"
version = v"0.12.0"

sources = [
    GitSource("https://github.com/PJK/libcbor.git",
              "ae000f44e8d2a69e1f72a738f7c0b6b4b7cc4fbf")
]

script = raw"""
cd ${WORKSPACE}/srcdir/libcbor*

mkdir build
cd build
cmake -S .. -B . \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DBUILD_SHARED_LIBS=ON

make -j${nproc} install
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libcbor", :libcbor)
]

dependencies = [
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
