# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "Faiss_CUDA"
version = v"1.10.0"

# Conda GPU packages build on 11.4, 11.8, 12.1, and 12.4: https://github.com/facebookresearch/faiss/blob/v1.10.0/.github/workflows/build-release.yml#L25-L99
cuda_versions = [
    # 11.4 does not provide cuda_profiler_api (used by faiss)
    "11.8", # 11.8 to have cuda_profiler_api, and SM 87;89;90 support.
    "12.1",
    "12.4",
] 

include(joinpath(@__DIR__, "..", "common.jl"))

# Override the default platforms
platforms = CUDA.supported_platforms()
filter!(p -> p["cuda"] in cuda_versions, platforms)
for cuda_version in cuda_versions
    push!(platforms, Platform("powerpc64le", "linux"; cuda=cuda_version))
    push!(platforms, Platform("x86_64", "windows"; cuda=cuda_version))
end

# Override the default products
products = [
    products...,
    FileProduct("include/faiss/gpu/GpuIndex.h", :faiss_gpu_gpuindex_h),
    FileProduct("include/faiss/c_api/gpu/GpuIndex_c.h", :faiss_c_api_gpu_gpuindex_c_h),
]

# Build for all supported CUDA toolkits
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform; static_sdk=true)

    # Download the CUDA nvcc redist for the host architecture (x86_64) for non-x86_64-linux-gnu platforms
    platform_sources = BinaryBuilder.AbstractSource[sources...]
    if !platforms_match(platform, Platform("x86_64", "linux"))
        cuda_version = platform["cuda"]
        push!(platform_sources, CUDA.cuda_nvcc_redist_source(cuda_version, "x86_64"))
    end

    build_tarballs(ARGS, name, version, platform_sources, script, [platform], products, [dependencies; cuda_deps];
                   lazy_artifacts=true,
                   julia_compat="1.9",
                   preferred_gcc_version=v"7",
                   augment_platform_block=CUDA.augment,
                   skip_audit=true,
                   dont_dlopen=true)
end
