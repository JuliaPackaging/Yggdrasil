# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CBQN"
version = v"2022.11.8"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/dzaima/CBQN.git", "4f9af9965c8c8fbb90b79168fa529ebe4124622c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd CBQN/
make shared-o3
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Libffi_jll", uuid="e9f186c6-92d2-5b65-8a66-fee21dc1b490"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
