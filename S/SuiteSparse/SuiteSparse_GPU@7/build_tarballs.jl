include("../common.jl")

using Base.BinaryPlatforms: arch, os

name = "SuiteSparse_GPU"
version_str = "7.8.0"
version = VersionNumber(version_str)

sources = suitesparse_sources(version)

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

# Bash recipe for building across all platforms
script = raw"""
PROJECTS_TO_BUILD="cholmod;spqr"

# Ensure CUDA is on the path
export CUDA_HOME=${WORKSPACE}/destdir/cuda;
export PATH=$PATH:$CUDA_HOME/bin
export CUDACXX=$CUDA_HOME/bin/nvcc

# nvcc thinks the libraries are located inside lib64, but the SDK actually has them in lib
ln -s ${CUDA_HOME}/lib ${CUDA_HOME}/lib64

# Enable CUDA
FLAGS+=(CUDA_PATH="$prefix/cuda")
CMAKE_OPTIONS+=(
        -DSUITESPARSE_USE_CUDA=ON
        -DSUITESPARSE_USE_SYSTEM_SUITESPARSE_CONFIG=ON
        -DSUITESPARSE_USE_SYSTEM_AMD=ON
        -DSUITESPARSE_USE_SYSTEM_COLAMD=ON
        -DSUITESPARSE_USE_SYSTEM_CAMD=ON
        -DSUITESPARSE_USE_SYSTEM_CCOLAMD=ON
        -DCMAKE_RELEASE_POSTFIX="_cuda"
    )
""" * build_script(use_omp = false, use_cuda = true)

# Products for the GPU builds of SuiteSparse
gpu_products = [
    LibraryProduct("libcholmod_cuda",                :libcholmod),
    LibraryProduct("libspqr_cuda",                   :libspqr),
    LibraryProduct("libgpuqrengine_cuda",            :libgpuqrengine),
    LibraryProduct("libsuitesparse_gpuruntime_cuda", :libsuitesparse_gpuruntime),
]

# Override the default platforms
platforms = CUDA.supported_platforms()
filter!(p -> arch(p) == "x86_64", platforms)

# Add dependency on SuiteSparse_jll
push!(dependencies, Dependency("SuiteSparse_jll"; compat = "=$version_str" ))

# build SuiteSparse_GPU for all supported CUDA toolkits
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    # Need the static SDK to let CMake detect the compiler properly
    cuda_deps = CUDA.required_dependencies(platform, static_sdk=true)

    build_tarballs(ARGS, name, version, sources, script, [platform],
                   gpu_products, [dependencies; cuda_deps]; lazy_artifacts=true,
                   julia_compat="1.11",preferred_gcc_version=v"9",
                   augment_platform_block=CUDA.augment,
                   skip_audit=true, dont_dlopen=true)
end
