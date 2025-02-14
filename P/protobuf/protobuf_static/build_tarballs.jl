# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include(joinpath(@__DIR__, "..", "common.jl"))

name = "protobuf_static"

script = raw"""
export BUILD_SHARED_LIBS=OFF
""" *
script

products = [
    FileProduct("lib/libprotobuf.a", :libprotobuf_static),
    FileProduct("lib/libprotobuf-lite.a", :libprotobuf_lite_static),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
