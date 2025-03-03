# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include(joinpath(@__DIR__, "..", "common.jl"))

name = "ProtocolBuffersLite"
# Cf. https://github.com/protocolbuffers/protobuf/blob/v22.0/version.json
version = VersionNumber(4, base_version.major, base_version.minor)

script = """
export BB_PROTOBUF_PRODUCT=$name
""" *
script

products = [
    LibraryProduct("lib$name", symbol) for (symbol, name) in protobuf_lite_library_symbols
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat, preferred_gcc_version)
