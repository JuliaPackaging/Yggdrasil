include("../common.jl")

build_csl(ARGS, v"0.5.3"; preferred_gcc_version=v"11", include_libmsvcrt=true, julia_compat="1.9")

# Build trigger: 0
