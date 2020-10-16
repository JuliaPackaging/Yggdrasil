include("../common.jl")

name, version, sources, script, platforms, products, dependencies = configure(v"1.4.2")

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7", lock_microarchitecture=false)
