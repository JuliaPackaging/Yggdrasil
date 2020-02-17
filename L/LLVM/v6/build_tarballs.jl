version = v"6.0.1"

include("../common.jl")

platforms = expand_cxxstring_abis(supported_platforms())
name, sources, script, products = configure(ARGS, version)
build_tarballs(ARGS, name, version, sources, script,
               platforms, products, dependencies,
               preferred_gcc_version=v"7", preferred_llvm_version=v"8")
