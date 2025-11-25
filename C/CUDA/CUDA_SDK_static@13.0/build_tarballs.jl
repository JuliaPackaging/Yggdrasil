using BinaryBuilder, Pkg

include("../common.jl")

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "CUDA_SDK_static"
version = CUDA.full_version(v"13.0")

platforms = [Platform("x86_64", "linux"),
             Platform("aarch64", "linux"),
             Platform("x86_64", "windows")]

full_platforms = Platform[]
for platform in platforms
    augmented_platform = deepcopy(platform)
    augmented_platform["cuda"] = "$(version.major)"
    push!(full_platforms, augmented_platform)
end

build_sdk(name, version, full_platforms; static=true)

# bump
