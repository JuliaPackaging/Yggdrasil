version = v"2.28.10"
include("../common.jl")

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.9", preferred_llvm_version=llvm_version)

# Build trigger: 2
