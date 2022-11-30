include("common.jl")
jllversion=v"1.10.0"
build_julia(ARGS, v"1.6.3"; jllversion)
build_julia(ARGS, v"1.7.0"; jllversion)
build_julia(ARGS, v"1.8.2"; jllversion)
build_julia(ARGS, v"1.9.0-DEV"; jllversion)
build_julia(ARGS, v"1.10.0-DEV"; jllversion)

