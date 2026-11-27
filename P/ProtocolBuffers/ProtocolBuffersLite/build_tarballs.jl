# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

common_path = normpath(@__DIR__, "..", "common")

include(joinpath(common_path, "common.jl"))

common_tree_hash = join(string.(Pkg.GitTools.tree_hash(common_path); base=16, pad=2))
common_tree_hash !== "5ccb81f015ddf4dd688f73ff3961d9009cd15eb3" && error("Tree hash mismatch for $common_path; got: $common_tree_hash")

name = "ProtocolBuffersLite"

build_protobuf(name, ARGS)
