# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include(joinpath(@__DIR__, "..", "common.jl"))

name = "protobuf"

script = raw"""
export BUILD_SHARED_LIBS=ON
""" *
script

products = [
    LibraryProduct("libprotobuf", :libprotobuf),
    LibraryProduct("libprotobuf-lite", :libprotobuf_lite),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
