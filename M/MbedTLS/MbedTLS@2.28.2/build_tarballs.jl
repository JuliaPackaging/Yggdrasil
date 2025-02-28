version = v"2.28.2"
include("../common.jl")

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.9")

# Build trigger: 2
