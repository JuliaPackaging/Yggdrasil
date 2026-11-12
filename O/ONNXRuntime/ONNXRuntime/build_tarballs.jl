# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "ONNXRuntime"
version = v"1.31.1"

include(joinpath(@__DIR__, "..", "common.jl"))

# Override the default sources
append!(sources, [
    ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x64-$version.zip", "5869e26bb25314375f2d5ef1877e3ea06b1543d6c710e6e4a1ec2f7177ab4b2c"; unpack_target="onnxruntime-x86_64-w64-mingw32"),
])

# The default SDK's libc++ breaks protobuf's constinit empty string
sources, script = require_macos_sdk("15.0", sources, script; deployment_target="11.0")

build_tarballs(ARGS, name, version, sources, script,
               platforms, products, dependencies;
               julia_compat = "1.10",
               lock_microarchitecture = false, # MLAS selects its -march kernels at run time
               preferred_gcc_version)
