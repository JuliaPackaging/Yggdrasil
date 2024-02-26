# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gh_cli"
version = v"2.35.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/cli/cli.git", "94fbbdf9b5b81a433c8bb60cd16b8d179822d834"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cli/
go build -v ./cmd/gh
mkdir ${bindir}
mv gh${exeext} ${bindir}/gh${exeext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    ExecutableProduct("gh", :gh)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:go, :c])
