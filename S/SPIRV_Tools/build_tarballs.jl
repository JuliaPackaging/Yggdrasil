# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SPIRV_Tools"
version = v"2024.1"

# Collection of sources required to build SPIRV-Tools
sources = [
    GitSource("https://github.com/KhronosGroup/SPIRV-Tools.git", "04896c462d9f3f504c99a4698605b6524af813c1"),
    # vendored dependencies, see the DEPS file
    GitSource("https://github.com/google/effcee.git", "19b4aa87af25cb4ee779a071409732f34bfc305c"),
    GitSource("https://github.com/google/googletest", "5df0241ea4880e5a846775d3efc8b873f7b36c31"),
    GitSource("https://github.com/google/re2.git", "ed9fc269e2fdb299afe59e912928d31ad3fdcf7d"),
    GitSource("https://github.com/KhronosGroup/SPIRV-Headers.git", "8b246ff75c6615ba4532fe4fde20f1be090c3764"),
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
dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9") # requires C++17 + filesystem
