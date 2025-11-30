# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include(joinpath(@__DIR__, "..", "common.jl"))

name = "ProtocolBuffersLite"

script = """
export BB_PROTOBUF_PRODUCT=$name
""" *
script

products = products_map[name]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat, preferred_gcc_version)
