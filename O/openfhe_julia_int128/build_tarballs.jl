# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include(joinpath(@__DIR__, "..", "openfhe_julia", "common.jl"))

# If you make changes in this file, e.g., to release a new version,
# be sure to also release a new version of `openfhe_julia` as well (see `../openfhe_julia/build_tarballs.jl`)
name = "openfhe_julia_int128"
version = v"0.3.6"

git_hash = "4939f1dd11ae2640b5bb397f731df8ef94307e74"

sources, script, platforms, products, dependencies = prepare_openfhe_julia_build(name, git_hash)

push!(dependencies, Dependency(PackageSpec(name="OpenFHE_int128_jll", uuid="a89a0bdd-1663-5679-8b21-c3a5388322bc"); compat="1.2.3"))

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"10.2.0")
