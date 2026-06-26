include("../common.jl")

build_csl(ARGS, v"1.1.2"; preferred_gcc_version=v"13", unix_staticlibs=false, windows_staticlibs=true, julia_compat="1.10")

# Build trigger: 1
