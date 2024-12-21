# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder

name = "rapidjson"
# make up patch 1.1.1 with recent changes of master branch
version = v"1.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Tencent/rapidjson.git", "ab1842a2dae061284c0a62dca1cc6d5e7e37e346")
]

# Bash recipe for building across all platforms
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

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("include/rapidjson/rapidjson.h", :rapidjson_h)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6")
