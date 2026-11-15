using BinaryBuilder

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "glslang"
version = v"15.0.0"

source = "https://github.com/KhronosGroup/glslang.git"
commit = "46ef757e048e760b46601e6e77ae0cb72c97bd2f" # tag 15.0.0

sources = [
    GitSource(source, commit)
]

script = raw"""
cd glslang

CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

# The SPIR-V optimizer needs a SPIRV-Tools to link against, and SPIRV_Tools_jll ships no
# import libraries on Windows, so its CMake config cannot be consumed there. 11.7.0 has the
# optimizer off already -- its CMake only enables it for an in-tree External/spirv-tools --
# so this keeps the artifacts as they are rather than making them differ per platform.
CMAKE_FLAGS+=(-DENABLE_OPT=OFF)

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} install
"""

# glslang 15 uses std::filesystem, which libc++ marks unavailable before macOS 10.15
sources, script = require_macos_sdk("10.15", sources, script)

# The products that we will ensure are always built
products = [
    ExecutableProduct("glslangValidator", :glslangValidator),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# glslang 15 is C++17 and links std::filesystem without -lstdc++fs, neither of which the
# default 4.8.5 can do
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               julia_compat="1.6", preferred_gcc_version=v"9")
