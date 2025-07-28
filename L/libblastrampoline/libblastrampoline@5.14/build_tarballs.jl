# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
version = v"5.14.0"

include("../common.jl")

sources = lbt_sources(version)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.13",  preferred_llvm_version=llvm_version
)

# Build trigger: 1
