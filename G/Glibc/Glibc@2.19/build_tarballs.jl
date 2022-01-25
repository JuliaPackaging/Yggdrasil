using BinaryBuilder

include("../common.jl")

name = "Glibc"
version = v"2.19"

sources = glibc_sources(version)
script = glibc_script()
platforms = glibc_platforms(version)
products = glibc_products()
dependencies = glibc_dependencies()

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", lock_microarchitecture=false)
