# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "FLANN_CUDA"
version = v"1.9.2"

cuda_versions = [
    "10.2",
    "11.4",
    "11.8",
    "12.0",
    "12.8",
]

platforms = expand_cxxstring_abis(CUDA.supported_platforms(; min_version=v"10.2"))
filter!(p -> p["cuda"] in cuda_versions, platforms)
filter!(p -> arch(p) == "x86_64", platforms)

include(joinpath(@__DIR__, "..", "common.jl"))

# Override the default products
products = [
    products...,
    LibraryProduct("libflann_cuda", :libflann_cuda),
]

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform) # ; static_sdk=true

    build_tarballs(ARGS, name, version, sources, script, [platform], products, [dependencies; cuda_deps];
                   augment_platform_block=CUDA.augment,
                   julia_compat="1.6",
    )
end
