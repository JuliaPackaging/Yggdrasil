# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("common.jl")

# If you make changes in this file, e.g., to release a new version,
# be sure to also release a new version of `openfhe_julia_int128` as well (see `../openfhe_julia_int128/build_tarballs.jl`)
name = "openfhe_julia"
version = v"0.3.11"

git_hash = "cfcba530b435735e77c7a4684bd16de9a62f7ac8"

sources, script, platforms, products, dependencies = prepare_openfhe_julia_build(name, git_hash)

push!(dependencies, Dependency(PackageSpec(name="OpenFHE_jll", uuid="a2687184-f17b-54bc-b2bb-b849352af807"); compat="1.2.3"))

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version = v"9")
