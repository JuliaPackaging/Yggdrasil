include("../common.jl")

build_csl(ARGS, v"1.4.0"; preferred_gcc_version=v"15", unix_staticlibs=false, windows_staticlibs=true, julia_compat="1.12")

# Build trigger: 0
