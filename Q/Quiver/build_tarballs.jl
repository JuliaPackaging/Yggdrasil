using BinaryBuilder

name = "Quiver"
version = v"0.2.0"

include("../../platforms/macos_sdks.jl")

sources = [
    GitSource("https://github.com/psrenergy/quiver.git",
              "c4b6c1027b675214f80b469d3b6185c0ac4bd16d"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/quiver

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DQUIVER_BUILD_TESTS=OFF \
    -DQUIVER_BUILD_C_API=ON \
    -DHAVE_GNU_STRERROR_R_EXITCODE=0 \
    -DHAVE_GNU_STRERROR_R_EXITCODE__TRYRUN_OUTPUT=""

cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE
"""

sources, script = require_macos_sdk("10.15", sources, script)

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
