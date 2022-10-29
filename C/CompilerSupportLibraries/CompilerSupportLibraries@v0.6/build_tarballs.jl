include("../common.jl")

build_csl(ARGS, v"0.6.2"; preferred_gcc_version=v"12", windows_staticlibs=true, julia_compat="1.9")

# Build trigger: 1
