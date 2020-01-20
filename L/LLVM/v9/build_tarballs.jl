version = v"9.0.1"

include("../common.jl")


# platforms = expand_cxxstring_abis(supported_platforms())
platforms = expand_cxxstring_abis([Windows(:x86_64), Windows(:i686)])
sources, script, products = configure(version, assert=false)
build_tarballs(ARGS, "LLVM", version, sources, script,
               platforms, products, dependencies,
               preferred_gcc_version=v"7", preferred_llvm_version=v"8")
