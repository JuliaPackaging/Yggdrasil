version = v"16.0.6"

include("../common.jl")

for configurations in configure_build(ARGS, version; experimental_platforms=true)
    build_tarballs(ARGS, configurations...;
        preferred_gcc_version=v"10", preferred_llvm_version=v"16", julia_compat="1.10")
end
#Let's build!! 3
