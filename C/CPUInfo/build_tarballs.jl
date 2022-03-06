# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase: os

name = "CPUInfo"
version = v"0.0.20200122"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pytorch/cpuinfo.git", "0e6bde92b343c5fbcfe34ecd41abf9515d54b4a7"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd cpuinfo
if [[ $target == *-w64-mingw32 ]]; then
    atomic_patch -p1 ../patches/lowercase-windows-include.patch
fi
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
    ..
cmake --build . -- -j $nproc
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> arch(p) != "aarch64" || os(p) != "macos", platforms) # aarch64-macos unsupported
filter!(p -> os(p) != "freebsd", platforms) # FreeBSD unsupported

# The products that we will ensure are always built
products = [
    LibraryProduct("libcpuinfo", :libcpuinfo),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
