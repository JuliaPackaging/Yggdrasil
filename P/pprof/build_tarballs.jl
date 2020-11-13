using BinaryBuilder

name = "pprof"

# Note that google/pprof doesn't have proper release versions. We are
# identifying a version by a specific commit hash, off of `pprof`'s
# main branch.

hash = "20978b51388db0648809a2c5cc88b494c7945ec1"
version = v"0.1.0"

# Collection of sources required to build pprof
sources = [
    GitSource("https://github.com/google/pprof.git",
              hash),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pprof/
mkdir -p ${bindir}
go build -o ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("pprof", :pprof),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :go])
