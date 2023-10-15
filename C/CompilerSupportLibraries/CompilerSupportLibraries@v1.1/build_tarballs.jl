include("../common.jl")

build_csl(ARGS, v"1.1.0"; preferred_gcc_version=v"13", windows_staticlibs=true, julia_compat="1.11")

# Build trigger: 1
