# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "peco"
version = v"0.5.7"

# Collection of sources required to complete build
sources = [
    "https://github.com/peco/peco/archive/v$(version).tar.gz" =>
    "9bf4f10b3587270834380e1ea939625bd47eaa166bfabd050e66fad3ffd8f9b0",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/peco-*/
go build -o ${bindir}/peco${exeext} cmd/peco/peco.go
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("peco", :peco)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers = [:go,:c])
