using BinaryBuilder

name = "Hjson"

hash = "bdaa45f5d9768665e3081b9fe64cd574f9e092d4"
version = v"4.4.0"

# Collection of sources required to build pprof
sources = [
    GitSource("https://github.com/hjson/hjson-go.git", hash),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hjson-go/hjson-cli
mkdir -p ${bindir}
go build -o ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("hjson-cli", :hjson),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :go], julia_compat="1.6")
