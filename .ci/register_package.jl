using BinaryBuilder

if length(ARGS) != 3
    error("Usage: register_package.jl <name> <version> <dependencies>")
end

name = ARGS[1]
version = VersionNumber(ARGS[2])
dependencies = strip.(split(ARGS[3], " "), '\'')

# Determine build version
build_version = BinaryBuilder.get_next_wrapper_version(name, version)

# Register JLL package using given metadata
BinaryBuilder.register_jll(name, build_version, dependencies)
