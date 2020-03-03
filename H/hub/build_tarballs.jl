# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "hub"
version = v"2.14.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/github/hub/archive/v2.14.1.tar.gz", "62c977a3691c3841c8cde4906673a314e76686b04d64cab92f3e01c3d778eb6f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hub-2.14.1/
mkdir -p ${bindir}
go build -o ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("hub", :hub)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers = [:go, :c])
