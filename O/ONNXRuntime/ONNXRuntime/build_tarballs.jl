# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ONNXRuntime"

include(joinpath(@__DIR__, "..", "common.jl"))
include(joinpath(@__DIR__, "..", "..", "..", "platforms", "macos_sdks.jl"))

append!(sources, [
    ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x64-$version.zip",
                  "5869e26bb25314375f2d5ef1877e3ea06b1543d6c710e6e4a1ec2f7177ab4b2c"; unpack_target="onnxruntime-x86_64-w64-mingw32"),
])

# ONNX Runtime is C++20, and the libc++ headers in the default macOS SDKs are too old. Those
# in the 14.0 SDK (libc++ 16) allocate when default-constructing a `std::string` during
# constant evaluation, which breaks protobuf's `constinit` empty string; 15.0 has libc++ 18.
sources, script = require_macos_sdk("15.0", sources, script; deployment_target="11.0")

build_tarballs(ARGS, name, version, sources, script,
               platforms, products, dependencies;
               julia_compat = "1.10",
               # MLAS compiles individual kernels with `-march=armv8.2-a+bf16` etc. and selects
               # them at runtime, so the compiler wrappers must not reject `-march`.
               lock_microarchitecture = false,
               preferred_gcc_version)
