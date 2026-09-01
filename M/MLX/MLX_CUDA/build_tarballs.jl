# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "MLX_CUDA"
version = v"0.25.2"

include(joinpath(@__DIR__, "..", "common.jl"))

platforms = CUDA.supported_platforms()

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

    build_tarballs(ARGS, name, version, sources, script, [platform], products, [dependencies; cuda_deps];
                   lazy_artifacts=true,
                   julia_compat,
                   preferred_gcc_version,
                   augment_platform_block=CUDA.augment,
                   skip_audit=true,
                   dont_dlopen=true)
end
