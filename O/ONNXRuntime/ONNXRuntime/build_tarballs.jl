# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ONNXRuntime"

include(joinpath(@__DIR__, "..", "common.jl"))

append!(sources, [
    ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x64-$version.zip",
                  "5869e26bb25314375f2d5ef1877e3ea06b1543d6c710e6e4a1ec2f7177ab4b2c"; unpack_target="onnxruntime-x86_64-w64-mingw32"),
])

build_tarballs(ARGS, name, version, sources, script,
               platforms, products, dependencies;
               julia_compat = "1.6",
               preferred_gcc_version)
