# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "spirv2clc"
version = v"0.2"

# Collection of sources required to build spirv2clc
sources = [
    GitSource("https://github.com/JuliaGPU/spirv2clc",
              "8396e706e24a8c20820f4c534b79394f16a85a43")
]

# Bash recipe for building across all platforms
script = raw"""
cd spirv2clc
install_license LICENSE

# spirv2clc's CMake build requires CMake >= 3.24, newer than the one shipped in
# the build environment, so use the one provided by CMake_jll (added as a host
# build dependency below) instead.
apk del cmake

# check-out vendored submodules (OpenCL-Headers, SPIRV-Headers, SPIRV-Tools)
# under external/. SPIRV-Tools is built from source because spirv2clc links
# against its internal optimizer API.
# TODO: use JLLs?
git submodule update --init --recursive

CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

# We already initialised the submodules above, so don't let CMake do it again.
CMAKE_FLAGS+=(-DSPIRV2CLC_UPDATE_SUBMODULES=OFF)

# We don't run the (lit/clang/FileCheck-based) regression tests nor the
# OpenCL test layer here, so skip configuring/building them entirely.
CMAKE_FLAGS+=(-DBUILD_TESTING=OFF)

# XXX: the library only has a C++ API, so we don't ship it; build just the tool.
#CMAKE_FLAGS+=(-DBUILD_SHARED_LIBS=ON)

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} spirv2clc

# Install only the `tools` component, i.e. the command-line translator. The
# build also produces libspirv2clc (a C++-only library) and vendored
# SPIR-V/OpenCL headers, none of which are useful as a JLL.
cmake --install build --component tools
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
# We only ship a standalone executable (no C++ library), so there is no ABI
# boundary for consumers and the C++ string ABI variants would be redundant.
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("spirv2clc", :spirv2clc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # The build requires CMake >= 3.24, newer than the one in the environment.
    HostBuildDependency(PackageSpec(name="CMake_jll", version="3.31.9")),
]

build_tarballs(ARGS,
               name, version, sources, script,
               platforms, products, dependencies;
               preferred_gcc_version=v"10",
               julia_compat="1.6")
