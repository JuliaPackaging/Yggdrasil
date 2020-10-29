# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "lazygit"
version = v"0.23.6"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jesseduffield/lazygit.git", "7c1889cd70b81d9f8438c197c3d2fc89e5695160")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd lazygit/
mkdir -p ${bindir}
go build -o ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("lazygit", :lazygit)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers = [:go, :c])
