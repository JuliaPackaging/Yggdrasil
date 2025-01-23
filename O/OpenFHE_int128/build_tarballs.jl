# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include(joinpath(pwd(), "..", "OpenFHE", "common.jl"))

# If you make changes in this file, e.g., to release a new version,
# be sure to also release a new version of `OpenFHE` as well (see `../OpenFHE/build_tarballs.jl`)
name = "OpenFHE_int128"
version = v"1.2.3"

git_hash = "7b8346f4eac27121543e36c17237b919e03ec058"

sources, script, platforms, products, dependencies = prepare_openfhe_build(name, git_hash)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"10.2.0")

# Build trigger: 1