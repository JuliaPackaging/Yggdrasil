# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ONNXRuntime"
version = v"1.10.0"

include(joinpath(@__DIR__, "..", "common.jl"))

# Override the default sources
append!(sources, [
    ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x64-$version.zip", "a0c6db3cff65bd282f6ba4a57789e619c27e55203321aa08c023019fe9da50d7"; unpack_target="onnxruntime-x86_64-w64-mingw32"),
    ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x86-$version.zip", "fd1680fa7248ec334efc2564086e9c5e0d6db78337b55ec32e7b666164bdb88c"; unpack_target="onnxruntime-i686-w64-mingw32"),
])

build_tarballs(ARGS, name, version, sources, script,
               platforms, products, dependencies;
               julia_compat = "1.6",
               preferred_gcc_version = v"8")
