include("../common.jl")

build_csl(ARGS, v"1.0.5"; preferred_gcc_version=v"12", windows_staticlibs=true, julia_compat="1.9")

# Build trigger: 3
