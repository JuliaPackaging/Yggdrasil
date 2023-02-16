using BinaryBuilder

include("../common.jl")

# Collection of sources required to build OpenBLAS
name = "OpenBLASConsistentFPCSR"
version = v"0.3.21"

sources = openblas_sources(version)
script = openblas_script(;aarch64_ilp64=true, num_64bit_threads=512, consistent_fpcsr=true)
# CONSISTENT_FPCSR = 1 works only for for x86/x86_64
# It should work for aarch64 but we have no aarch64 machine for debugging,
# so we exclude it for the moment
platforms = expand_gfortran_versions(supported_platforms(; exclude=p -> arch(p) != "x86_64"))
# push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))
products = openblas_products()
dependencies = openblas_dependencies(platforms)

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"6", lock_microarchitecture=false, julia_compat="1.6")
