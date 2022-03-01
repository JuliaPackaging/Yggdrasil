# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg.Types

name = "ROCmDeviceLibs"
version = v"4.2.0"

# Collection of sources required to build ROCm-Device-Libs
sources = [
    ArchiveSource("https://github.com/RadeonOpenCompute/ROCm-Device-Libs/archive/rocm-$(version).tar.gz",
                  "34a2ac39b9bb7cfa8175cbab05d30e7f3c06aaffce99eed5f79c616d0f910f5f"),
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
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake \
      -DLLVM_DIR="${prefix}/lib/cmake/llvm" \
      -DClang_DIR="${prefix}/lib/cmake/clang" \
      -DLLD_DIR="${prefix}/lib/cmake/ldd" \
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
    BuildDependency(PackageSpec(; name="LLVM_full_jll", version=v"12.0.1")),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.7",
               preferred_gcc_version=v"8", preferred_llvm_version=v"11")
