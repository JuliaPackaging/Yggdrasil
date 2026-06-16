# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ONNXRuntime"
version = v"1.19.0"

include(joinpath(@__DIR__, "..", "common.jl"))

# Override the default sources
append!(sources, [
    ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x64-$version.zip", "1d796da7001e4843858d0587aa8232976abf9e0ae7fba8deb7fa8156e440efb7"; unpack_target="onnxruntime-x86_64-w64-mingw32"),
    ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x86-$version.zip", "202e72a11948136c758c8be26a6e47c471670fb8559caa326d3efb30c0469421"; unpack_target="onnxruntime-i686-w64-mingw32"),
])

build_tarballs(ARGS, name, version, sources, script,
               platforms, products, dependencies;
               julia_compat = "1.6",
               preferred_gcc_version = v"11")
