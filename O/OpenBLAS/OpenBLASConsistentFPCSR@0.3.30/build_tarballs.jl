using BinaryBuilder

include("../common.jl")

# Collection of sources required to build OpenBLAS
name = "OpenBLASConsistentFPCSR"
version = v"0.3.30"

sources = openblas_sources(version)
script = openblas_script(;aarch64_ilp64=true, num_64bit_threads=512, bfloat16=true, consistent_fpcsr=true)
platforms = expand_gfortran_versions(supported_platforms(; exclude=p -> !(arch(p) in ("x86_64", "aarch64"))))
products = openblas_products()
preferred_llvm_version = v"16.0.6"
dependencies = openblas_dependencies(platforms; llvm_compilerrt_version=preferred_llvm_version)

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"11", lock_microarchitecture=false,
               julia_compat="1.11", preferred_llvm_version=preferred_llvm_version)

# Build trigger: 1
