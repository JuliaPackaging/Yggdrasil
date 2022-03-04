using BinaryBuilder

name = "glslang"
version = v"11.7.0"

source = "https://github.com/KhronosGroup/glslang.git"
commit = "925503088e2bcd76921b1e102c37fc320bace254" # Nov 11, 2021 (tag 11.7.0)

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

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} install
"""

# The products that we will ensure are always built
products = [
    ExecutableProduct("glslangValidator", :glslangValidator),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("SPIRV_Tools_jll")
]

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
