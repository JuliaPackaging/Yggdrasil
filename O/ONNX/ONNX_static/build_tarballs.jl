# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

common_path = normpath(@__DIR__, "..", "common") 

include(joinpath(common_path, "common.jl"))

common_tree_hash = join(string.(Pkg.GitTools.tree_hash(common_path); base=16, pad=2))
common_tree_hash !== "999742a02e40f71196a9b142088915a3b2e8580d" && error("Tree hash mismatch for $common_path; got: $common_tree_hash")

name = "ONNX_static"

script = """
export BB_RECIPE_NAME=$name
""" *
script

products = products_map[name]
dependencies = dependencies_map[name]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat, preferred_gcc_version)
