using BinaryBuilder

include("../common.jl")

# Collection of sources required to build OpenBLAS
name = "OpenBLAS"
version = v"0.3.25"

sources = openblas_sources(version)
script = openblas_script(;aarch64_ilp64=true, num_64bit_threads=512)
platforms = openblas_platforms(;experimental=true)
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))
products = openblas_products()
dependencies = openblas_dependencies(platforms)

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"6", lock_microarchitecture=false,
               julia_compat="1.11", preferred_llvm_version=v"13.0.1")

# Build trigger: 1
