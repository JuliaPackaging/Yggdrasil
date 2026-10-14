# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include("common.jl")

# If you make changes in this file, e.g., to release a new version,
# be sure to also release a new version of `OpenFHE_int128` as well (see `../OpenFHE_int128/build_tarballs.jl`)
name = "OpenFHE"
version = v"1.6.0"
git_hash = "6206d24f9eefefc620b524a4f2b9f308feb91e9f"

sources, script, platforms, products, dependencies = prepare_openfhe_build(name, git_hash)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.10", preferred_gcc_version = v"10.2.0")
