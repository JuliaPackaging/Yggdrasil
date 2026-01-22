using BinaryBuilder

name = "Quiver"
version = v"0.1.0"

sources = [
    GitSource("https://github.com/psrenergy/quiver.git",
              "00b7cdc3e4187db73c405c1d407ad4b1664e40d7"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/quiver

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DQUIVER_BUILD_TESTS=OFF \
    -DQUIVER_BUILD_C_API=ON

cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libquiver", :libquiver),
    LibraryProduct("libquiver_c", :libquiver_c),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.7",
               preferred_gcc_version=v"13")
