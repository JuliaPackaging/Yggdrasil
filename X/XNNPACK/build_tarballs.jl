# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "XNNPACK"
version = v"0.0.20200225"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/google/XNNPACK.git", "7493bfb9d412e59529bcbced6a902d44cfa8ea1c"),
    DirectorySource("./bundled"),
    GitSource("https://github.com/pytorch/cpuinfo.git", "d5e37adf1406cf899d7d9ec1d317c47506ccb970"),
    GitSource("https://github.com/Maratyszcza/FP16.git", "ba1d31f5eed2eb4a69e4dea3870a68c7c95f998f"),
    GitSource("https://github.com/Maratyszcza/FXdiv.git", "f8c5354679ec2597792bc70a9e06eff50c508b9a"),
    GitSource("https://github.com/Maratyszcza/psimd.git", "10b4ffc6ea9e2e11668f86969586f88bc82aaefa"),
    GitSource("https://github.com/Maratyszcza/pthreadpool.git", "7ad026703b3109907ad124025918da15cfd3f100"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/XNNPACK
atomic_patch -p1 ../patches/xnnpack-disable-fast-math.patch
mkdir build
cd build
# Omitted cmake define of CPUINFO_SOURCE_DIR as there is a patch for cpuinfo
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR=$libdir \
    -DCLOG_SOURCE_DIR=$WORKSPACE/srcdir/cpuinfo \
    -DFP16_SOURCE_DIR=$WORKSPACE/srcdir/FP16 \
    -DFXDIV_SOURCE_DIR=$WORKSPACE/srcdir/FXdiv \
    -DPSIMD_SOURCE_DIR=$WORKSPACE/srcdir/psimd \
    -DPTHREADPOOL_SOURCE_DIR=$WORKSPACE/srcdir/pthreadpool \
    -DXNNPACK_LIBRARY_TYPE=shared \
    -DXNNPACK_BUILD_TESTS=OFF \
    -DXNNPACK_BUILD_BENCHMARKS=OFF \
    ..
cmake --build . -- -j $nproc
make install
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libXNNPACK", :libxnnpack),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("CPUInfo_jll", v"0.0.20200122"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"9",
    julia_compat="1.6")
