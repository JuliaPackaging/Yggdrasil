# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "flatbuffers"
version = v"25.2.10"

sources = [
    GitSource("https://github.com/google/flatbuffers.git",
              "14b58f1b4d808471b80dfb066965a967103ab730"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/flatbuffers

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DFLATBUFFERS_BUILD_FLATC=ON \
    -DFLATBUFFERS_BUILD_FLATHASH=OFF \
    -DFLATBUFFERS_BUILD_TESTS=OFF \
    -DFLATBUFFERS_INSTALL=ON
cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE
"""

platforms = expand_cxxstring_abis(supported_platforms())

products = [
    ExecutableProduct("flatc", :flatc),
    FileProduct("include/flatbuffers/flatbuffers.h", :flatbuffers_h),
    FileProduct("lib/cmake/flatbuffers/BuildFlatBuffers.cmake", :BuildFlatBuffers_cmake),
]

dependencies = Dependency[]

# `std::optional::value()` needs macOS 10.14 on Intel macOS.
sources, script = require_macos_sdk("10.14", sources, script)

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6", preferred_gcc_version=v"7")
