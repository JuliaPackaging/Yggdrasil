# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SPIRV_Tools"
version = v"2020.6"

# Collection of sources required to build SPIRV-Tools
sources = [
    GitSource("https://github.com/KhronosGroup/SPIRV-Tools.git", "4c2f34a504817cc96d3e8b0435265a743cb2038a"),
    # vendored dependencies
    GitSource("https://github.com/google/effcee.git", "33d438fb1939e94e5507d38dee9d999f60a03d96"), # 2019.1
    GitSource("https://github.com/google/re2.git", "166dbbeb3b0ab7e733b278e8f42a84f6882b8a25"), # 2020-11-01
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
    BuildDependency(PackageSpec(name="SPIRV_Headers_jll", version=v"1.5.4"))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
