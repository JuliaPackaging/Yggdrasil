# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

common_path = normpath(@__DIR__, "..", "common") 

include(joinpath(common_path, "common.jl"))

common_tree_hash = join(string.(Pkg.GitTools.tree_hash(common_path); base=16, pad=2))
common_tree_hash !== "37eba731fd6665eef66eed57181f0316b3235541" && error("Tree hash mismatch for $common_path; got: $common_tree_hash")

name = "ONNX"

script = """
export BB_RECIPE_NAME=$name
""" *
script

products = products_map[name]
dependencies = dependencies_map[name]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat, preferred_gcc_version)
