include("../common.jl")

# Offset to add to the version number
version_offset = v"0.1.0"
# Minimum Julia version supported: this is important to decide which versions of
# the dependencies to use, in particular the JLL stdlibs.
min_julia_version = v"1.3"

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, configure(version_offset, min_julia_version)...; julia_compat="~1.0, ~1.1, ~1.2, ~1.3, ~1.4, ~1.5")
