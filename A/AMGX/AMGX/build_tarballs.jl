include("../common.jl")

build_amgx("AMGX", platforms, AbstractDependency[], CUDA.augment)
