# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder

name = "rapidjson"
version = v"1.1.0"
sources = [
    GitSource("https://github.com/Tencent/rapidjson.git", "f54b0e47a08782a6131cc3d60f94d038fa6e0a51")
]

script = raw"""
cd ${WORKSPACE}/srcdir/rapidjson
cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release \
    -DRAPIDJSON_BUILD_DOC=No -DRAPIDJSON_BUILD_EXAMPLES=No -D RAPIDJSON_BUILD_TESTS=No -DRAPIDJSON_BUILD_CXX17=Yes -DRAPIDJSON_BUILD_CXX11=No 
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