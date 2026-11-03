# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))


name = "SPIRV_Tools"
version = v"2026.4"

# Collection of sources required to build SPIRV-Tools
sources = [
    GitSource("https://github.com/KhronosGroup/SPIRV-Tools.git",
              "ef96ed763b43b59b33b31b362f09a02b729fa1c9"; tag="v$(version)"),
    # the SPIRV-Headers revision from DEPS; its other dependencies are only for the tests
    GitSource("https://github.com/KhronosGroup/SPIRV-Headers.git",
              "496543121ce6419f23d6fa5d7194ba66c36212d2"),
]

# Bash recipe for building across all platforms
script = raw"""
# use CMake from JLLs
apk del cmake

mv SPIRV-Headers SPIRV-Tools/external/spirv-headers

cd SPIRV-Tools
install_license LICENSE

CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Build all shared libraries (downstream projects seem to depend on it)
CMAKE_FLAGS+=(-DBUILD_SHARED_LIBS=ON)
CMAKE_FLAGS+=(-DSPIRV_TOOLS_BUILD_STATIC=OFF)

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

# Remove unwanted static libraries
rm -f $prefix/lib/*.a
"""

sources, script = require_macos_sdk("10.15", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("spirv-as", :spirv_as),
    ExecutableProduct("spirv-dis", :spirv_dis),
    ExecutableProduct("spirv-val", :spirv_val),
    ExecutableProduct("spirv-opt", :spirv_opt),
    ExecutableProduct("spirv-cfg", :spirv_cfg),
    ExecutableProduct("spirv-link", :spirv_link),
    ExecutableProduct("spirv-lint", :spirv_lint),
    ExecutableProduct("spirv-objdump", :spirv_objdump),
    ExecutableProduct("spirv-reduce", :spirv_reduce),
    ExecutableProduct("spirv-diff", :spirv_diff),
    LibraryProduct("libSPIRV-Tools", :libSPIRV_Tools),
    LibraryProduct("libSPIRV-Tools-opt", :libSPIRV_Tools_opt),
    LibraryProduct("libSPIRV-Tools-diff", :libSPIRV_Tools_diff),
    LibraryProduct("libSPIRV-Tools-link", :libSPIRV_Tools_link),
    LibraryProduct("libSPIRV-Tools-lint", :libSPIRV_Tools_lint),
    LibraryProduct("libSPIRV-Tools-reduce", :libSPIRV_Tools_reduce),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # CMake 3.22.1 or higher is required
    HostBuildDependency("CMake_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"10", # requires C++17 + filesystem
               julia_compat="1.6")
