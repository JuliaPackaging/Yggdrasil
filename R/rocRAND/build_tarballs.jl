# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "rocRAND"
version = v"4.0.0"

# Collection of sources required to build
sources = [
    ArchiveSource("https://github.com/ROCmSoftwarePlatform/rocRAND/archive/rocm-$(version).tar.gz",
                  "1cafdbfa15cde635bd424d2a858dc5cc94d668f9a211ff39606ee01ed1715f41"), # 4.0.0
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/rocRAND*/

amdgpu_targets="gfx900,gfx906,gfx908,gfx1010,gfx1011,gfx1012"

mkdir build && cd build
export ROCM_PATH=${prefix}
export HIP_CLANG_PATH=${prefix}/tools
export HIP_CLANG_HCC_COMPAT_MODE=1
export HIP_RUNTIME=ROCclr
export HIP_COMPILER=clang
export HIP_PLATFORM=rocclr
export HIPCC_VERBOSE=1
cmake -DCMAKE_PREFIX_PATH=${prefix} \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_COMPILER=${prefix}/hip/bin/hipcc \
      -DAMDGPU_TARGETS=$(echo $amdgpu_targets | tr ',' ';') \
      ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    # TODO: cxx03
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct(["librocrand"], :librocrand, ["rocrand/lib"]),
    LibraryProduct(["libhiprand"], :libhiprand, ["hiprand/lib"]),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(; name="LLVM_full_jll", version=v"11.0.1")),
    Dependency("hsa_rocr_jll"),
    Dependency("ROCmCompilerSupport_jll"),
    Dependency("ROCmOpenCLRuntime_jll"),
    Dependency("HIP_jll"),
    Dependency("rocm_cmake_jll"),
    Dependency("rocminfo_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               preferred_gcc_version=v"8", preferred_llvm_version=v"11")
