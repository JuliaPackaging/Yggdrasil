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

    build_tarballs(ARGS, name, version, sources, script, [platform], products, [dependencies; cuda_deps];
                   lazy_artifacts=true,
                   julia_compat,
                   preferred_gcc_version,
                   augment_platform_block=CUDA.augment,
                   skip_audit=true,
                   dont_dlopen=true)
end
