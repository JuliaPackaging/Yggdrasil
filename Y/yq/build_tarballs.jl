using BinaryBuilder

name = "yq"

version = v"4.42.1"

# Collection of sources required to build yq
sources = [
    GitSource("https://github.com/mikefarah/yq", "9adde1ac14bb283b8955d2b0d567bcaf3c69e639"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/yq
mkdir -p ${bindir}
go build -o ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("yq", :yq),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :go], julia_compat="1.6")
