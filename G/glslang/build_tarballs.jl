using BinaryBuilder

name = "glslang"
version = v"8.13.3743"

source = "https://github.com/KhronosGroup/glslang.git"
commit = "bcf6a2430e99e8fc24f9f266e99316905e6d5134" # April 27th, 2020

sources = [
    GitSource(source, commit)
]

script_linux = raw"""
cd glslang


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

build_tarballs(ARGS, name, version, sources, script_linux, platforms, products, dependencies)