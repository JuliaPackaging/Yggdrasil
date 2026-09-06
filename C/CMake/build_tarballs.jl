# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CMake"
version = v"4.4.1"

# Collection of sources required to build CMake
sources = [
    GitSource("https://github.com/Kitware/CMake", "d1cffecacdfd7d6fb0cda0d1e0bf1ba30b967019"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/CMake

# The musl in our toolchains (1.1.19) predates pthread_getname_np (musl 1.2.3)
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cmlibuv-musl-pthread_getname_np.patch

cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE:STRING=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_TESTING:BOOL=OFF
cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE.rst
"""

# Build for all supported platforms.
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("cmake", :cmake),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"; compat="3.0.16")
]

# Build the tarballs, and possibly a `build.jl` as well.
# We use GCC 7 because we need C++17 (`std::make_unique`)
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")
