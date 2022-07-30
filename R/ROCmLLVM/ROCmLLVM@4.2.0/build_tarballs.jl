version = v"12.0.0"
rocm_version = v"4.2.0"

include("../common.jl")
include("../../../L/LLVM/common.jl")

rocm_config = configure_build(
    ARGS, version; experimental_platforms=true,
    git_path="https://github.com/RadeonOpenCompute/llvm-project",
    git_ver="b204d7f0cae65b6cd4446eec50fc1fb675d582af",
    custom_name="ROCmLLVM", custom_version=rocm_version, static=true,
    platform_filter=rocm_platform_filter, rocm_llvm=true)

build_tarballs(
    ARGS, rocm_config...;
    preferred_gcc_version=v"7", preferred_llvm_version=v"9", julia_compat="1.7")
