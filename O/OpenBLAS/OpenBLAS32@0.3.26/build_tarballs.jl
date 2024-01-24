using BinaryBuilder

include("../common.jl")

# Collection of sources required to build OpenBLAS
name = "OpenBLAS32"
version = v"0.3.26"

sources = openblas_sources(version)
script = openblas_script(openblas32=true, bfloat16=true)
platforms = openblas_platforms()
products = openblas_products()
dependencies = openblas_dependencies(platforms)

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"11", lock_microarchitecture=false,
               julia_compat="1.11", preferred_llvm_version=v"13.0.1")

# Build trigger: 1
