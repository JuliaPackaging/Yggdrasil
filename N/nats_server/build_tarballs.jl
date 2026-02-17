# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "nats_server"
version = v"2.10.18"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/nats-io/nats-server.git", "57d23acf2737d692c24116476e12111c6499d96b")

]

# Bash recipe for building across all platforms
# using flags from '.goreleaser.yml'
# https://github.com/nats-io/nats-server/blob/f2c7a9d37f1a7a612814abf9365c52ed6687ec4f/.goreleaser.yml
script = raw"""
cd $WORKSPACE/srcdir/nats-server/
NAME=${bindir}/nats-server${exeext}
CGO_ENABLED=0 GO111MODULE=on go build -o $NAME\
    -trimpath\
    -ldflags "-w"
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
