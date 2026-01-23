using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "slope"
version = v"6.3.0"

sources = [
    GitSource("https://github.com/jolars/libslope.git", "25c165ed1e52ee99da57c81d42ba5c504f1c98b4"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libslope

# Build main library
cmake -B build \
    -DBUILD_TESTING=OFF \
    -DBUILD_JULIA_BINDINGS=ON \
    -DJlCxx_DIR=$prefix/lib/cmake/JlCxx \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DJulia_PREFIX=${prefix}

cmake --build build --parallel ${nproc}
cmake --install build

install_license $WORKSPACE/srcdir/libslope/LICENSE
"""

# `std::optionals()`'s `value()` needs macOS 10.14 SDK
sources, script = require_macos_sdk("11.3", sources, script)

include("../../L/libjulia/common.jl")
julia_versions = filter(v -> v >= v"1.10", julia_versions)
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libslopejll", :libslopejll),
]

dependencies = [
    BuildDependency("Eigen_jll"),
    BuildDependency("libjulia_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("LLVMOpenMP_jll", platforms = filter(Sys.isapple, platforms)),
    Dependency("libcxxwrap_julia_jll"; compat = "0.14.7"),
]

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"11", julia_compat = "1.10"
)
