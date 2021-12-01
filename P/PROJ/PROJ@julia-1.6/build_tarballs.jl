include("../common.jl")

# Offset to add to the version number
version_offset = v"0.2.0"
# Minimum Julia version supported: this is important to decide which versions of
# the dependencies to use, in particular the JLL stdlibs.
min_julia_version = v"1.6"

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, configure(version_offset, min_julia_version)...; julia_compat="1.6")
