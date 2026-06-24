include("../common.jl")

build_csl(ARGS, v"1.3.1"; preferred_gcc_version=v"14", unix_staticlibs=false, windows_staticlibs=true, julia_compat="1.12")

# Build trigger: 0
