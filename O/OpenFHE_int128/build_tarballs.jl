# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include(joinpath(pwd(), "..", "OpenFHE", "common.jl"))

# If you make changes in this file, e.g., to release a new version,
# be sure to also release a new version of `OpenFHE` as well (see `../OpenFHE/build_tarballs.jl`)
name = "OpenFHE_int128"
version = v"1.2.4"

git_hash = "6bcca756e9d52b4db3dd2168414df8a7316b1a61"

sources, script, platforms, products, dependencies = prepare_openfhe_build(name, git_hash)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.10", preferred_gcc_version = v"10.2.0")
