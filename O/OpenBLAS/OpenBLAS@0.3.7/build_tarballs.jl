using BinaryBuilder

include("../common.jl")

# Collection of sources required to build OpenBLAS
name = "OpenBLAS"
version = v"0.3.7"

sources = openblas_sources(version)
script = openblas_script()
platforms = openblas_platforms()
products = openblas_products()
dependencies = []

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")

