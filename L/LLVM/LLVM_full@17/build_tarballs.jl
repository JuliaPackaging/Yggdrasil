version = v"17.0.6"

include("../common.jl")
function cond(platform)
    arch(platform) == "armv7l"
end
build_tarballs(ARGS, configure_build(ARGS, version; platform_filter=cond, experimental_platforms=true)...;
               preferred_gcc_version=v"13", preferred_llvm_version=v"16", julia_compat="1.12")
# Build trigger: 7
