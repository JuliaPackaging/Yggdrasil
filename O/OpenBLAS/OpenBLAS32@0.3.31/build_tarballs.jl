using BinaryBuilder

include("../common.jl")

# Collection of sources required to build OpenBLAS
name = "OpenBLAS32"
version = v"0.3.31"

# NOTE: riscv64: Disabling `_zvfbfwma` in a patch doesn't work. Next idea: Build with GCC 15.

sources = openblas_sources(version)
script = openblas_script(openblas32=true, bfloat16=true, float16=true)
platforms = openblas_platforms(; version)
products = openblas_products()
preferred_llvm_version = v"18.1.7"
dependencies = openblas_dependencies(platforms; llvm_compilerrt_version=preferred_llvm_version)

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"15", lock_microarchitecture=false,
               julia_compat="1.11", preferred_llvm_version=preferred_llvm_version)

# Build trigger: 0
