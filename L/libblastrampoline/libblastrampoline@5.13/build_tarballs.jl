# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
version = v"5.13.1"

include("../common.jl")

sources = lbt_sources(version)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.12",  preferred_llvm_version=llvm_version
)

# Build trigger: 4
