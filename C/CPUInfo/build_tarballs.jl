# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CPUInfo"
version = v"0.0.20201217"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pytorch/cpuinfo.git", "5916273f79a21551890fd3d56fc5375a78d1598d"),
]

# Bash recipe for building across all platforms
script = raw"""
if [[ $target == aarch64-apple-darwin* ]]; then
    cmake_extra_args="-DCMAKE_OSX_ARCHITECTURES=arm64"
fi

cd $WORKSPACE/srcdir
cd cpuinfo
mkdir build
cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR=$libdir \
    -DCPUINFO_BUILD_UNIT_TESTS=OFF \
    -DCPUINFO_BUILD_MOCK_TESTS=OFF \
    -DCPUINFO_BUILD_BENCHMARKS=OFF \
    -DCPUINFO_LIBRARY_TYPE=shared \
    $cmake_extra_args \
    ..
cmake --build . -- -j $nproc
make install
if [[ $target == *-w64-mingw32 ]]; then
    install -Dvm 755 libcpuinfo.dll "${libdir}/libcpuinfo.dll"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcpuinfo", :libcpuinfo),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
