# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SPIRV_Tools"
version = v"2024.3"

# Collection of sources required to build SPIRV-Tools
sources = [
    GitSource("https://github.com/KhronosGroup/SPIRV-Tools.git", "0cfe9e7219148716dfd30b37f4d21753f098707a"),
    # vendored dependencies, see the DEPS file
    GitSource("https://github.com/google/effcee.git", "d74d33d93043952a99ae7cd7458baf6bc8df1da0"),
    GitSource("https://github.com/google/googletest", "1d17ea141d2c11b8917d2c7d029f1c4e2b9769b2"),
    GitSource("https://github.com/google/re2.git", "4a8cee3dd3c3d81b6fe8b867811e193d5819df07"),
    GitSource("https://github.com/KhronosGroup/SPIRV-Headers.git", "2acb319af38d43be3ea76bfabf3998e5281d8d12"),
]

# Bash recipe for building across all platforms
script = raw"""
# put vendored dependencies in places they will be picked up by the build system
mv effcee SPIRV-Tools/external/effcee
mv re2 SPIRV-Tools/external/re2
mv googletest SPIRV-Tools/external/googletest
mv SPIRV-Headers SPIRV-Tools/external/spirv-headers

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

# Skip spirv-objdump, which fails to build on some platforms
sed -i '/add_spvtools_tool(TARGET spirv-objdump/,+8d' tools/CMakeLists.txt

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
    ExecutableProduct("spirv-dis", :spirv_dis),
    ExecutableProduct("spirv-val", :spirv_val),
    ExecutableProduct("spirv-opt", :spirv_opt),
    ExecutableProduct("spirv-cfg", :spirv_cfg),
    ExecutableProduct("spirv-link", :spirv_link),
    ExecutableProduct("spirv-lint", :spirv_lint),
    ExecutableProduct("spirv-reduce", :spirv_reduce),
    LibraryProduct("libSPIRV-Tools-shared", :libSPIRV_Tools),
]

# Dependencies that must be installed before this package can be built
dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8") # requires C++17 + filesystem
