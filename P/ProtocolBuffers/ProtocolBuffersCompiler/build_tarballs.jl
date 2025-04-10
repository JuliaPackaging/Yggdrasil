# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include(joinpath(@__DIR__, "..", "common.jl"))

name = "ProtocolBuffersCompiler"
# Cf. https://github.com/protocolbuffers/protobuf/blob/v22.0/version.json
version = base_version

script = """
export BB_PROTOBUF_PRODUCT=$name
""" *
script

products = vcat([
    LibraryProduct("lib$name", symbol) for (symbol, name) in protoc_library_symbols
], [
    ExecutableProduct("$binary_symbol", :binary_symbol) for binary_symbol in binary_symbols
])

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat, preferred_gcc_version)
