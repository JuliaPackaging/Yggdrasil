# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include(joinpath(pwd(), "..", "OpenFHE", "common.jl"))

name = "OpenFHE_128"
version = v"1.2.3"

# copy patch file from OpenFHE
mkdir(joinpath(pwd(), "bundled", "patches"))
cd(joinpath(pwd(), "..", "OpenFHE", "bundled", "patches", "windows-fix-cmake-libdir.patch"),
   joinpath(pwd(), "bundled", "patches", "windows-fix-cmake-libdir.patch"))

sources, script, platforms, products, dependencies = prepare_openfhe_build(name)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"10.2.0")
