include("../common.jl")

build_csl(ARGS, v"0.5.4"; preferred_gcc_version=v"11", windows_staticlibs=true, julia_compat="1.9")

# Build trigger: 1
