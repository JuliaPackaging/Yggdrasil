using BinaryBuilder

include("../common.jl")

name = "Binutils"
version = v"2.41"

sources = binutils_sources(version)
script = binutils_script()
platforms = binutils_platforms()
products = binutils_products()
dependencies = binutils_dependencies()

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

