version = v"9.0.1"

include("../common.jl")

# Change this line
platforms = expand_cxxstring_abis(supported_platforms())
sources, script, products = configure(version, assert=false)
build_tarballs(ARGS, "LLVM", version, sources, script,
               platforms, products, dependencies,
               preferred_gcc_version=v"7", preferred_llvm_version=v"8")
