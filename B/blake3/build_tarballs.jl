using BinaryBuilder

name = "blake3"
version = v"1.8.5"
sources = [
    GitSource(
        "https://github.com/BLAKE3-team/BLAKE3/",
        "93a431c78a52d7ccf0f366f106467f5070e6075e";
        unpack_target = "BLAKE3"
    ),
]

script = raw"""
cd ${WORKSPACE}/srcdir/BLAKE3
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
