using BinaryBuilder

include("../common.jl")

name = "OpenBLASHighCoreCount"
version = v"0.3.5"

sources = openblas_sources(version)
script = openblas_script()
platforms = openblas_platforms()
products = openblas_products()
dependencies = []

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")

