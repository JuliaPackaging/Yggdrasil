# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("../OpenFHE/commom.jl")

name = "OpenFHE_128"
version = v"1.2.3"

sources, script, platforms, products, dependencies = prepare_openfhe_build(name)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"10.2.0")
