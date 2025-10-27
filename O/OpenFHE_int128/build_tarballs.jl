# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include(joinpath(pwd(), "..", "OpenFHE", "common.jl"))

# If you make changes in this file, e.g., to release a new version,
# be sure to also release a new version of `OpenFHE` as well (see `../OpenFHE/build_tarballs.jl`)
name = "OpenFHE_int128"
version = v"1.4.0"

git_hash = "aa8a86e1143f1e47d4354bdd757080e903ba5875"

sources, script, platforms, products, dependencies = prepare_openfhe_build(name, git_hash)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.10", preferred_gcc_version = v"10.2.0")
