using BinaryBuilder

name = "pprof"

# Note that google/pprof doesn't have proper release versions. We are
# identifying a version by a specific commit hash, off of `pprof`'s
# main branch.

hash = "b5a4dc8f4f2afdee77047b6aae3834140efc83ed"
version = v"1.0.1"

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
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    ExecutableProduct("pprof", :pprof),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Graphviz_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :go], julia_compat="1.6")
