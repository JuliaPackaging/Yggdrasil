using BinaryBuilder

name = "blake3"
version = v"1.8.6"
sources = [
    GitSource(
        "https://github.com/BLAKE3-team/BLAKE3/",
        "77b257eee7da5cd608eaf6be8343d3a4c9776af2",
    ),
]

script = raw"""
cd ${WORKSPACE}/srcdir
install_license LICENSE_CC0
cmake -S c -B c/build -DBUILD_SHARED_LIBS=true -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build c/build --parallel ${nproc}
cmake --install c/build
"""

platforms = supported_platforms()

products = Product[
    LibraryProduct("libblake3", :libblake3),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6", preferred_gcc_version=v"8")
