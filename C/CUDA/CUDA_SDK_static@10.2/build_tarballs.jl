using BinaryBuilder, Pkg

include("../common_10.2.jl")

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "CUDA_SDK_static"
version = CUDA.full_version(v"10.2")

platforms = [Platform("x86_64", "linux"),
             Platform("aarch64", "linux"),
             Platform("x86_64", "macos"),
             Platform("x86_64", "windows")]

build_sdk(name, version, platforms; static=true)
