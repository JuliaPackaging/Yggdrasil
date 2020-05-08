# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SPIRV_Tools"
version = v"2020.2"

# Collection of sources required to build IGC
sources = [
    GitSource("https://github.com/KhronosGroup/SPIRV-Tools.git", "fd8e130510a6b002b28eee5885a9505040a9bdc9"),
    # vendored dependencies
    GitSource("https://github.com/google/effcee.git", "6fa2a03cebb4fb18fbad086d53d1054928bef54e"), # 2019.0
    GitSource("https://github.com/google/re2.git", "209eda1b607909cf3c9ad084264039546155aeaa"), # 2020-04-01
]

# Bash recipe for building across all platforms
script = raw"""
# put vendored dependencies in places they will be picked up by the build system
mv effcee SPIRV-Tools/external/effcee
mv re2 SPIRV-Tools/external/re2

cd SPIRV-Tools
install_license LICENSE

CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

# Skip tests
CMAKE_FLAGS+=(-DSPIRV_SKIP_TESTS=ON)

# Don't use -Werror
CMAKE_FLAGS+=(-DSPIRV_WERROR=OFF)

# Point to the SPIRV Headers JLL
CMAKE_FLAGS+=(-DSPIRV-Headers_SOURCE_DIR=${prefix})

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("spirv-as", :spirv_as),
    ExecutableProduct("spirv-cfg", :spirv_cfg),
    ExecutableProduct("spirv-dis", :spirv_dis),
    ExecutableProduct("spirv-link", :spirv_link),
    ExecutableProduct("spirv-opt", :spirv_opt),
    ExecutableProduct("spirv-reduce", :spirv_reduce),
    ExecutableProduct("spirv-val", :spirv_val),
    LibraryProduct("libSPIRV-Tools-shared", :libSPIRV_Tools),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("SPIRV_Headers_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
