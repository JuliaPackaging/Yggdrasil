# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder

name = "rapidjson"
version = v"1.1.0"
sources = [
    GitSource("https://github.com/Tencent/rapidjson.git", "ab1842a2dae061284c0a62dca1cc6d5e7e37e346")
]

script = raw"""
cd ${WORKSPACE}/srcdir/rapidjson
cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DRAPIDJSON_BUILD_DOC=No \
    -DRAPIDJSON_BUILD_EXAMPLES=No \
    -DRAPIDJSON_BUILD_TESTS=No \
    -DRAPIDJSON_BUILD_CXX17=Yes
cmake --build build --parallel ${nproc}
cmake --install build
"""

platforms = [AnyPlatform()]

products = [
    FileProduct("include/rapidjson/rapidjson.h", :rapidjson_h)
]


dependencies = [
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
