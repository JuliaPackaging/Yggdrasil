using BinaryBuilder

include("../common.jl")

# Collection of sources required to build OpenBLAS
name = "OpenBLAS32"
version = v"0.3.23"

sources = openblas_sources(version)
script = openblas_script(openblas32=true)
platforms = openblas_platforms()
products = openblas_products()
dependencies = openblas_dependencies(platforms)

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"6", preferred_llvm_version=v"13.0.1", lock_microarchitecture=false, julia_compat="1.10")


# Build trigger: 3
