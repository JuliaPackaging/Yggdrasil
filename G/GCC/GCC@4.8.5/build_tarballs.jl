using BinaryBuilder

include("../common.jl")

name = "GCC"
version = v"4.8.5"

sources = gcc_sources(version)
script = gcc_script()
platforms = gcc_platforms()
products = gcc_products()
dependencies = gcc_dependencies()

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

