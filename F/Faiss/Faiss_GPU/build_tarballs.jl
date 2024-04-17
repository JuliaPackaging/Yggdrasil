# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "Faiss_GPU"

cuda_versions = ["11.8", "12.1"] # 11.8 to have SM 87;89;90 support. Conda GPU packages build on 11.4 and 12.1: https://github.com/facebookresearch/faiss/blob/v1.8.0/.circleci/config.yml#L358

include(joinpath(@__DIR__, "..", "common.jl"))

# Override the default platforms
platforms = CUDA.supported_platforms()
filter!(p -> arch(p) == "x86_64", platforms)

filter!(p -> p["cuda"] in cuda_versions, platforms)

# Build for all supported CUDA toolkits
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform)

    build_tarballs(ARGS, name, version, sources, script, [platform], products, [dependencies; cuda_deps];
                   lazy_artifacts=true,
                   julia_compat="1.6",
                   preferred_gcc_version=v"7",
                   augment_platform_block=CUDA.augment,
                   skip_audit=true,
                   dont_dlopen=true)
end
# trigger yggy
