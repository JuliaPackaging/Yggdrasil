# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "esbuild"
version = v"0.25.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/evanw/esbuild.git", "e9174d671b1882758cd32ac5e146200f5bee3e45")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/esbuild/cmd/esbuild
mkdir -p ${bindir}
go build -o ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    ExecutableProduct("esbuild", :esbuild)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:go, :c])
