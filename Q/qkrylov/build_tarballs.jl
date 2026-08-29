# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg, BinaryBuilderBase

# Include Yggdrasil platform helpers for macOS SDK management and CUDA
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "qkrylov"
version = v"0.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sjp95/qkrylov.git", "9d1160736de86937cd39f63121c8d7188208669b")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/qkrylov*

# Set TMPDIR so nvcc doesn't fill up the small sandbox /tmp
export TMPDIR=${WORKSPACE}/tmpdir
mkdir -p ${TMPDIR}

if [[ "${bb_full_target}" == *cuda\+none* || "${bb_full_target}" != *cuda* ]]; then
    CUDA_OPTION="OFF"
    cmake_cuda_args="-DKokkos_ENABLE_CUDA=OFF"
else
    CUDA_OPTION="ON"
    export PATH=$PATH:$prefix/cuda/bin/
    export CUDA_PATH=$prefix/cuda/
    [ -f $prefix/cuda/lib/libcuda.so ] || ln -s $prefix/cuda/lib/stubs/libcuda.so $prefix/cuda/lib/libcuda.so
    [ -e $prefix/cuda/lib64 ] || ln -s $prefix/cuda/lib $prefix/cuda/lib64
    cmake_cuda_args="\
        -DKokkos_ENABLE_CUDA=ON \
        -DCMAKE_CUDA_HOST_COMPILER=$CXX \
        -DCMAKE_CUDA_COMPILER=$prefix/cuda/bin/nvcc \
        -DCMAKE_CUDA_FLAGS=-gencode=arch=compute_80,code=compute_80 \
        -DCMAKE_EXE_LINKER_FLAGS=-Wl,--allow-shlib-undefined \
        -DCMAKE_SHARED_LINKER_FLAGS=-Wl,--allow-shlib-undefined \
        -DKokkos_ARCH_AMPERE80=ON \
    "
fi

rm -rf build
mkdir -p build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      -DQKRYLOV_BUILD_TESTS=OFF \
      -DQKRYLOV_BUILD_PYTHON=OFF \
      ${cmake_cuda_args} \
      ..

make -j${nproc}
make install
install_license ../LICENSE

# Clean up CUDA stub
if [[ "${bb_full_target}" != *cuda\+none* && "${bb_full_target}" == *cuda* ]]; then
    [ -L $prefix/cuda/lib/libcuda.so ] && rm -f $prefix/cuda/lib/libcuda.so
    [ -L $prefix/cuda/lib64 ] && rm -f $prefix/cuda/lib64
fi
"""

# Request macOS SDK 10.13 or newer
sources, script = require_macos_sdk("10.13", sources, script)

# Augment platform block for CUDA runtime resolution
augment_platform_block = CUDA.augment

# Base CPU platforms
cpu_platforms = supported_platforms()
cpu_platforms = expand_cxxstring_abis(cpu_platforms)
filter!(p -> nbits(p) != 32, cpu_platforms)
for p in cpu_platforms
    if CUDA.is_supported(p) && !haskey(p, "cuda")
        p["cuda"] = "none"
    end
end

# CUDA platforms (Linux x86_64 for CUDA 12)
cuda_platforms = expand_cxxstring_abis(CUDA.supported_platforms(min_version=v"12.0", max_version=v"12.999"))
filter!(p -> arch(p) == "x86_64", cuda_platforms)

all_platforms = [cpu_platforms; cuda_platforms]

# The products that we will ensure are always built
products = [
    LibraryProduct("libqkrylov", :libqkrylov)
]

# Base dependencies for CPU builds
dependencies = AbstractDependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, all_platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, all_platforms)),
]

# Build the tarballs
for platform in all_platforms
    should_build_platform(triplet(platform)) || continue
    _dependencies = copy(dependencies)
    is_cuda = haskey(platform, "cuda") && platform["cuda"] != "none"
    if is_cuda
        append!(_dependencies, CUDA.required_dependencies(platform; static_sdk=true))
        push!(_dependencies, Dependency(PackageSpec(name="CUDA_Driver_jll")))
    end
    build_tarballs(ARGS, name, version, sources, script, [platform],
                   products, _dependencies;
                   augment_platform_block,
                   julia_compat="1.10",
                   preferred_gcc_version=v"11",
                   lazy_artifacts=true,
                   dont_dlopen=is_cuda)
end
