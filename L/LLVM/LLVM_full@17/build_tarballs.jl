version = v"17.0.6+"

include("../common.jl")

build_tarballs(ARGS, configure_build(ARGS, version; experimental_platforms=true, git_ver=llvm_tags[v"17.0.6"])...;
               preferred_gcc_version=v"10", preferred_llvm_version=v"16", julia_compat="1.11")
#Let's build!!
