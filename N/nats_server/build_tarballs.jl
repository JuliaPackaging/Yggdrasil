# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "nats_server"
version = v"2.9.21"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/nats-io/nats-server.git", "b2e7725aed60882176f8c95dadd3fa371385accf")
    # ArchiveSource("https://github.com/nats-io/nats-server/archive/refs/tags/v$(version).tar.gz", "e547ef512b59bd124e6851ee288584f6fd08cee3654f8c4a570abe11bc8d70a1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nats-server/
go build -o ${bindir}/nats-server
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("nats-server", :nats_server)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:go, :c])
