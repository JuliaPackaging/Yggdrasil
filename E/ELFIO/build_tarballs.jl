using BinaryBuilder

name = "ELFIO"
version = v"3.12"
sources = [
    GitSource("https://github.com/serge1/ELFIO.git", "8ae6cec5d60495822ecd57d736f66149da9b1830")
]

script = raw"""
cd ${WORKSPACE}/srcdir/ELFIO
cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release \
        -DELFIO_BUILD_EXAMPLES=no -DELFIO_BUILD_TESTS=No
cmake --build build --parallel ${nproc}
cmake --install build
"""

platforms = [AnyPlatform()]

products = [
    FileProduct("include/elfio/elfio.hpp", :elfio_hpp)
]


dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
