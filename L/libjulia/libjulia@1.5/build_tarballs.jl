include("../common.jl")

version = v"1.5.1"

name, version, sources, script, platforms, products, dependencies = configure(v"1.5.1")

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7", lock_microarchitecture=false)

