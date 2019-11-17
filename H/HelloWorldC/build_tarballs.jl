using BinaryBuilder

name = "HelloWorldC"
version = v"1.0.0"

# No sources, we're just building the testsuite
sources = [
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${prefix}/bin
cc -o ${prefix}/bin/hello_world${exeext} -g -O2 /usr/share/testsuite/c/hello_world/hello_world.c
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("hello_world", :hello_world),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
