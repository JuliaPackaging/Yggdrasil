version = v"2.26.0"
include("../common.jl")

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.7")

