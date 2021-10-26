include("common.jl")
jllversion=v"1.7.0"
build_julia(ARGS, v"1.6.0"; jllversion)
build_julia(ARGS, v"1.7.0-beta3"; jllversion)
