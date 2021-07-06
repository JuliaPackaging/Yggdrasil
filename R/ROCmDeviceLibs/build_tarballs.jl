# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg.Types

name = "ROCmDeviceLibs"
version = v"4.0.0"

# Collection of sources required to build ROCm-Device-Libs
sources = [
    ArchiveSource("https://github.com/RadeonOpenCompute/ROCm-Device-Libs/archive/rocm-$(version).tar.gz",
                  "d0aa495f9b63f6d8cf8ac668f4dc61831d996e9ae3f15280052a37b9d7670d2a"), # 4.0.0
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/ROCm-Device-Libs*/
mkdir build && cd build

# we set CMAKE_TOOLCHAIN_FILE because it builds a host executable for use in the build process
# we don't ship any executable code, so this is ok
cmake -DCMAKE_PREFIX_PATH=${prefix} \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN} \
      ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
]

#platforms = [p for p in supported_platforms() if Sys.islinux(p)]

# The products that we will ensure are always built
products = [
    FileProduct("amdgcn/bitcode/", :bitcode_path),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"8", preferred_llvm_version=v"11")
