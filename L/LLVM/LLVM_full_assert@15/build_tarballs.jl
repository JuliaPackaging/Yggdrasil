version = v"15.0.7"


include("../common.jl")

build_tarballs(ARGS, configure_build(ARGS, version; assert=true, experimental_platforms=true)...;
               preferred_gcc_version=v"7", preferred_llvm_version=v"12", julia_compat="1.10")
#It's building time!!
