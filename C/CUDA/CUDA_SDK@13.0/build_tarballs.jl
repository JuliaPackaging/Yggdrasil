using BinaryBuilder, Pkg

include("../common.jl")

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "CUDA_SDK"
version = CUDA.full_version(v"13.0")

platforms = [Platform("x86_64", "linux"),
             Platform("aarch64", "linux"),
             Platform("x86_64", "windows")]

build_sdk(name, version, platforms; static=false)
