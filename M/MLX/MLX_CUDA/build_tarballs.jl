# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "MLX_CUDA"
version = v"0.32.4"

include(joinpath(@__DIR__, "..", "common.jl"))

# An artifact is selected for drivers supporting its CUDA version or a later minor one, so build for the oldest
# toolkit supporting MLX (12.0, as for CCCL 3), and for those adding GPU archs (12.8, 12.9); MLX does not support
# CUDA 13.1, so CUDA 13.x drivers use the 13.0 artifact
cuda_versions = ["12.0", "12.8", "12.9", "13.0"]

platforms = CUDA.supported_platforms()
filter!(p -> p["cuda"] in cuda_versions, platforms)

# Build for all supported CUDA toolkits
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform; static_sdk=true)
    cuda_libraries = [
        RuntimeDependency(PackageSpec(name="CUDA_Compiler_jll")), # NVRTC, for kernels compiled at run time
        Dependency("CUDNN_jll"; compat="9"),
        RuntimeDependency(PackageSpec(name="CUDA_Runtime_Headers_jll")), # headers for NVRTC
    ]

    # Download the CUDA nvcc redist for the host architecture (x86_64) for non-x86_64-linux-gnu platforms
    platform_sources = BinaryBuilder.AbstractSource[sources...]
    if !platforms_match(platform, Platform("x86_64", "linux"))
        cuda_version = platform["cuda"]
        push!(platform_sources, CUDA.cuda_nvcc_redist_source(cuda_version, "x86_64"))
    end

    build_tarballs(ARGS, name, version, platform_sources, script, [platform], products, [dependencies; cuda_deps; cuda_libraries];
                   lazy_artifacts=true,
                   julia_compat,
                   preferred_gcc_version,
                   augment_platform_block=CUDA.augment,
                   skip_audit=true,
                   dont_dlopen=true)
end
