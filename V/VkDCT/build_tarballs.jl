using BinaryBuilder
using Base.BinaryPlatforms: arch

# The version of this JLL
name = "VkDCT"
version = v"1.3.4"

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

# Sources - VkFFT release and bundled shim/patches
sources = [
    GitSource("https://github.com/DTolm/VkFFT.git",
              "066a17c17068c0f11c9298d848c2976c71fad1c1"),
    DirectorySource("./bundled"),
]

# The script to build the binary
script = raw"""
cd ${WORKSPACE}/srcdir

# Apply patches
atomic_patch -p1 -d VkFFT patches/fix_log2_ambiguity.patch

# Set up CUDA environment
export CUDA_HOME=${WORKSPACE}/destdir/cuda
export PATH=$PATH:$CUDA_HOME/bin
export CUDACXX=$CUDA_HOME/bin/nvcc

# nvcc expects libraries in lib64, but the SDK has them in lib
ln -s ${CUDA_HOME}/lib ${CUDA_HOME}/lib64

# Enter the inner directory where headers are located
cd VkFFT/vkFFT

# Copy the bundled shim source
cp ${WORKSPACE}/srcdir/dct_shim.cu .

mkdir -p ${libdir}

nvcc -O3 -std=c++11 --shared -cudart shared -Xcompiler -fPIC -arch=sm_60 -o ${libdir}/libvkfft_dct.so dct_shim.cu -I. -lcuda -lnvrtc

install_license ../LICENSE
"""

# The products that we will ensure are always built
products = [
    LibraryProduct("libvkfft_dct", :libvkfft_dct),
]

# Platforms - build for all supported CUDA versions on x86_64
platforms = CUDA.supported_platforms()
filter!(p -> arch(p) == "x86_64", platforms)

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform, static_sdk=true)

    build_tarballs(ARGS, name, version, sources, script, [platform],
                   products, cuda_deps;
                   preferred_gcc_version=v"9",
                   julia_compat="1.10",
                   augment_platform_block=CUDA.augment,
                   lazy_artifacts=true,
                   dont_dlopen=true)
end
