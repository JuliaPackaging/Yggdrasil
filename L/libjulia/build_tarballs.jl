include("common.jl")
jllversion=v"1.7.0"
build_julia(ARGS, v"1.6.3"; jllversion)
build_julia(ARGS, v"1.7.0-rc1"; jllversion)
build_julia(ARGS, v"1.8.0-DEV"; jllversion)
