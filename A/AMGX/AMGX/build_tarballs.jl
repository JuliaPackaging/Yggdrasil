include("../common.jl")

build_amgx(ARGS, "AMGX", platforms, AbstractDependency[], CUDA.augment)
