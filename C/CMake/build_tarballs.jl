# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CMake"
version = v"3.29.3"

# Collection of sources required to build CMake
sources = [
    GitSource("https://github.com/Kitware/CMake", "b39fb31bf411c3925bd937f8cffbc471c2588c34"),
    DirectorySource("bundled/"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/CMake

# Add support for libblastrampoline to the FindBLAS/FindLAPACK modules
# Upstream PR https://gitlab.kitware.com/cmake/cmake/-/merge_requests/9557
# It will be included in 3.30
atomic_patch -p1 $WORKSPACE/srcdir/patches/01_libblastrampoline.patch

mkdir build
cd build/

cmake -B . -S .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE:STRING=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_TESTING:BOOL=OFF \
    -GNinja

ninja
ninja -j${nproc}
ninja install
"""

# Build for all supported platforms.
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("cmake", :cmake),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"; compat="3.0.12")
]

# Build the tarballs, and possibly a `build.jl` as well.
# We use GCC 7 because we need C++17 (`std::make_unique`)
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")
