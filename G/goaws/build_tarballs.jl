# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "goaws"
version = v"0.4.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Admiral-Piett/goaws.git", "441c9dc79f38f041a398935b8b53549789fa6100")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/goaws/
mkdir -p ${bindir}
go build -o ${bindir} app/cmd/goaws.go
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("goaws", :goaws)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:go, :c])
