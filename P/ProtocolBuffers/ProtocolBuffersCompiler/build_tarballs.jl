# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include(joinpath(@__DIR__, "..", "common.jl"))

name = "ProtocolBuffersCompiler"
# Cf. https://github.com/protocolbuffers/protobuf/blob/v28.2/version.json
version = VersionNumber(base_version.minor, base_version.patch)

script = raw"""
export BB_PROTOBUF_BUILD_SHARED_LIBS=ON
export BB_PROTOBUF_PRODUCT=protoc
""" *
script

products = vcat([
    LibraryProduct("libprotoc", :libprotoc),
    ExecutableProduct("protoc", :protoc),
], [
    LibraryProduct(String(lib), lib) for lib in additional_library_symbols
])

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"9")
