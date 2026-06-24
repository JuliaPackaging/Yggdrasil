version = v"2.24.0"
include("../common.jl")

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_llvm_version=llvm_version)

# Build trigger: 1
