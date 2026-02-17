using BinaryBuilder

# Set sources and other environment variables.
name = "azurite"
version = v"3.29.0"
sources = GitSource[]

script = "version=$(version)\n" * raw"""
apk add --update nodejs npm
cd ${prefix}
npm install azurite@${version}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built.
products = [
    FileProduct("node_modules/azurite/dist/src/azurite.js", :azurite),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("NodeJS_16_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
