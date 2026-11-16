# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "qwtw"
version = v"3.0.0"

sources = [
    GitSource("https://github.com/ig-or/qwtw.git",
              "d50bc08a90389bc7ca9185769ff0d7aabffd16c6"),
    GitSource("https://github.com/ig-or/qwt.git",
              "8a5ec6c5e507047c44860f3e3bdd8b0b1df9f922"),
]

script = raw"""
# Qt 6.10 requires CMake >= 3.22; use CMake_jll from the host prefix
apk del cmake

# Populate vendored Qwt submodule directory (and move out of srcdir root so
# BinaryBuilder's automatic license check sees a single top-level directory)
rm -rf ${WORKSPACE}/srcdir/qwtw/extern/qwt
mv ${WORKSPACE}/srcdir/qwt ${WORKSPACE}/srcdir/qwtw/extern/qwt

cd ${WORKSPACE}/srcdir/qwtw

CMAKE_EXTRA_ARGS=()
if [[ "${target}" == *apple-darwin* ]]; then
    CMAKE_EXTRA_ARGS+=(
        -DQT_HOST_PATH=${host_prefix}
        -DCMAKE_PREFIX_PATH=${host_prefix}
        -DQT_NO_APPLE_SDK_AND_XCODE_CHECK=ON
    )
else
    CMAKE_EXTRA_ARGS+=(
        -DQT_HOST_PATH=${host_prefix}
    )
fi

cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DNO_VERSION_INFO=ON \
    -DWITH_UDP_SYNC=ON \
    -DUSE_MGL=OFF \
    "${CMAKE_EXTRA_ARGS[@]}"

cmake --build build --parallel ${nproc}
cmake --install build

install_license ${WORKSPACE}/srcdir/qwtw/LICENSE
"""

# Install MacOSX14.0 SDK to match Qt6Base_jll 6.10 and provide UniformTypeIdentifiers + C++23 std::filesystem
sources, script = require_macos_sdk("14.0", sources, script; deployment_target="12")

platforms = [
    Platform("x86_64",  "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64",  "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64",  "windows"),
]
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libqwtw", :qwtw),
    ExecutableProduct("qwproc", :qwproc),
]

dependencies = [
    HostBuildDependency("CMake_jll"),
    HostBuildDependency("Qt6Base_jll"),
    Dependency("Qt6Base_jll"; compat="~6.10.2"),
    Dependency("Libglvnd_jll"; compat="1.7.0"),
    Dependency("CompilerSupportLibraries_jll"),
    BuildDependency("Vulkan_Headers_jll"),
]

# GCC 13 provides C++23 support and avoids GCC <= 12 ICEs with Qt6 headers on MinGW;
# LLVM 16 matches Qt6Base_jll's build toolchain.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6",
               preferred_gcc_version=v"13",
               preferred_llvm_version=v"16.0.6")
