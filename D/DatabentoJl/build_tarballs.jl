using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "DatabentoJl"
version = v"0.1.0"

# Sources
sources = [
    # 1. Your Package Source (Public GitHub)
    GitSource("https://github.com/harris-azmon/databento-julia.git", "49b499f35c1ad617aff37963451b06820d78ceaa"),

    # 2. Databento C++ Library (v0.30.0)
    GitSource("https://github.com/databento/databento-cpp.git", "49baedc33bd00b24d7503822c0c2ce6274477c18"),
]

# Bash recipe for building
script = raw"""
# Move to the C++ wrapper directory
cd $WORKSPACE/srcdir/databento-julia/deps

rm -rf build
mkdir build && cd build

# We use FETCHCONTENT_SOURCE_DIR_DATABENTO to tell CMake to use the
# checked-out databento-cpp from 'sources' instead of downloading it.
cmake -DCMAKE_INSTALL_PREFIX="$prefix" \
      -DCMAKE_FIND_ROOT_PATH="$prefix" \
      -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DJulia_PREFIX="$prefix" \
      -DFETCHCONTENT_SOURCE_DIR_DATABENTO=${WORKSPACE}/srcdir/databento-cpp \
      ..

make -j${nproc}
make install

# Install license
install_license ${WORKSPACE}/srcdir/databento-julia/LICENSE
"""

sources, script = require_macos_sdk("10.14", sources, script)

# Platforms we are targeting (Expanding ABIs for C++ compatibility)
include("../../L/libjulia/common.jl")
filter!(>=(v"1.10"), julia_versions)
platforms = vcat(libjulia_platforms.(julia_versions)...)
filter!(p -> nbits(p) == 64, platforms)
platforms = expand_cxxstring_abis(platforms)

# Products
products = [
    LibraryProduct("libdatabento_jl", :libdatabento_jl; dont_dlopen=true)
]

# Dependencies
dependencies = [
    BuildDependency(PackageSpec(; name="libjulia_jll", version="1.11.0")),
    Dependency("libcxxwrap_julia_jll"; compat="~0.14.0"),
    Dependency("OpenSSL_jll"),
    Dependency("Zstd_jll"),
]

@assert libjulia_min_julia_version <= v"1.10.0"

# Build the tarballs
# We prefer GCC 9 to ensure glibc compatibility with older linux distros (e.g. CentOS 7)
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat=libjulia_julia_compat(julia_versions), preferred_gcc_version=v"9")
