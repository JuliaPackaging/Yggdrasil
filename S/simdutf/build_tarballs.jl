using BinaryBuilder

include(joinpath("..", "..", "platforms", "macos_sdks.jl"))

name = "simdutf"
version = v"9.1.1"

sources = [
    GitSource("https://github.com/simdutf/simdutf.git",
              "9dd35adc5f2c87a53c5a0e6e5b43af6fffe7187e")
]

script = raw"""
cd ${WORKSPACE}/srcdir/simdutf
mkdir build
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DSIMDUTF_TESTS=OFF \
    -DSIMDUTF_TOOLS=OFF \
    -DSIMDUTF_ICONV=OFF \
    -DSIMDUTF_BENCHMARKS=OFF
cmake --build build
cmake --install build
install_license LICENSE-APACHE LICENSE-MIT
"""

sources, script = require_macos_sdk("10.15", sources, script)

platforms = expand_cxxstring_abis(supported_platforms())

products = [
    LibraryProduct(["libsimdutf"], :libsimdutf),
    FileProduct("include/simdutf.h", :simdutf_h),
    FileProduct("include/simdutf_c.h", :simdutf_c_h),
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"11")
