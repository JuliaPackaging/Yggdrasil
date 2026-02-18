using BinaryBuilder, Pkg

name = "vroom"
version = v"1.14.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/VROOM-Project/vroom.git", "1fd711bc8c20326dd8e9538e2c7e4cb1ebd67bdb")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd vroom/src
make
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GLPK_jll", uuid="e8aa6df9-e6ca-548a-97ff-1f85fc5b8b98"))
    Dependency(PackageSpec(name="jq_jll", uuid="f8f80db2-c0ba-59e9-a5c3-38d72e3c5ac2"))
]

# Build the tarballs, and possibly a `build.jl` as well.
# Need GCC 10 because the makefile uses `-std=c++20`
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"10")
