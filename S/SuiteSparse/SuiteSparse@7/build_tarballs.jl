# Build counter: 0
include("../common.jl")

name = "SuiteSparse"
version = v"7.8.3"

sources = suitesparse_sources(version)

# Bash recipe for building across all platforms
script = raw"""
PROJECTS_TO_BUILD="suitesparse_config;amd;btf;camd;ccolamd;colamd;cholmod;klu;ldl;umfpack;rbio;spqr"
""" * build_script(use_omp = false, use_cuda = false)

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.11")

# Build trigger: 1
