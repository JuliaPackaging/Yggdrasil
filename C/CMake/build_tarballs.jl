# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CMake"
version = v"3.31.3"

# Collection of sources required to build CMake
sources = [
    GitSource("https://github.com/Kitware/CMake", "41abd532b64f178017ed4ffdbdb5af42d9056a8d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/CMake

cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE:STRING=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_TESTING:BOOL=OFF
cmake --build build --parallel ${nproc}
cmake --install build
"""

# Build for all supported platforms.
platforms = expand_cxxstring_abis(supported_platforms())
# OpenSSL is not available for riscv64
filter!(p -> arch(p) != "riscv64", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("cmake", :cmake),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"; compat="3.0.15")
]

# Build the tarballs, and possibly a `build.jl` as well.
# We use GCC 7 because we need C++17 (`std::make_unique`)
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")
