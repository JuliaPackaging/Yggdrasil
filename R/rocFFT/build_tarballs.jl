# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "rocFFT"
version = v"4.2.0"

# Collection of sources required to build
sources = [
    ArchiveSource("https://github.com/ROCmSoftwarePlatform/rocFFT/archive/rocm-$(version).tar.gz",
                  "db29c9067f0cfa98bddd3574f6aa7200cfc790cc6da352d19e4696c3f3982163"),
    #DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/rocFFT*/

amdgpu_targets="gfx803,gfx900,gfx906,gfx908,gfx1010,gfx1011,gfx1012"

mkdir build && cd build
ln -s ${prefix}/bin/clang ${prefix}/tools/clang
export ROCM_PATH=${prefix}
export HIP_CLANG_PATH=$WORKSPACE/destdir/tools
export HIP_CLANG_HCC_COMPAT_MODE=1
export HIP_RUNTIME=rocclr
export HIP_COMPILER=clang
export HIP_PLATFORM=amd
export HIP_ROCCLR_HOME=${prefix}/hip
export HIPCC_VERBOSE=7
cmake -DCMAKE_PREFIX_PATH=${prefix} \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_COMPILER=$WORKSPACE/destdir/hip/bin/hipcc \
      -DAMDGPU_TARGETS=$(echo $amdgpu_targets | tr ',' ';') \
      ..
make -j${nproc}
make install
rm ${prefix}/tools/clang
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
    LibraryProduct(["librocfft", "librocfft.so.0"], :librocfft),
    LibraryProduct(["librocfft-device", "librocfft-device.so.0"], :librocfft_device),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version=v"4.2.0")),
    Dependency("hsa_rocr_jll"; compat="4.2.0"),
    Dependency("ROCmCompilerSupport_jll"; compat="4.2.0"),
    Dependency("ROCmOpenCLRuntime_jll"; compat="4.2.0"),
    Dependency("HIP_jll"; compat="4.2.0"),
    Dependency("rocm_cmake_jll"),
    Dependency("rocminfo_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               julia_compat="1.7",
               preferred_gcc_version=v"8")
