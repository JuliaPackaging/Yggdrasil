# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "Faiss_CUDA"
version = v"1.9.0"

# Conda GPU packages build on 11.4 and 12.1: https://github.com/facebookresearch/faiss/blob/v1.9.0/.github/workflows/build.yml#L182-L260
cuda_versions = [
    # 11.4 does not provide cuda_profiler_api (used by faiss)
    "11.8", # 11.8 to have cuda_profiler_api, and SM 87;89;90 support.
    "12.1",
] 

include(joinpath(@__DIR__, "..", "common.jl"))

# Override the default platforms
platforms = CUDA.supported_platforms()
filter!(p -> arch(p) == "x86_64", platforms)

filter!(p -> p["cuda"] in cuda_versions, platforms)

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

    build_tarballs(ARGS, name, version, sources, script, [platform], products, [dependencies; cuda_deps];
                   lazy_artifacts=true,
                   julia_compat="1.6",
                   preferred_gcc_version=v"7",
                   augment_platform_block=CUDA.augment,
                   skip_audit=true,
                   dont_dlopen=true)
end
# trigger yggy
