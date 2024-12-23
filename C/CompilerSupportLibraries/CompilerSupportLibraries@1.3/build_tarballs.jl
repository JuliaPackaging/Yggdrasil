include("../common.jl")

build_csl(ARGS, v"1.3.0"; preferred_gcc_version=v"13", windows_staticlibs=true, julia_compat="1.12")

# Build trigger: 0
