# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "duf"
version = v"0.5.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/muesli/duf.git", "4c15e83a7cac83f402c860fd513c6ff85fea5e19")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd duf/
mkdir -p ${bindir}
go build -o ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("duf", :duf)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers = [:go, :c])
