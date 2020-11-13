using BinaryBuilder

name = "ghr"
version = v"0.13.0"

# Collection of sources required to build ghr
sources = [
    GitSource("https://github.com/tcnksm/ghr.git",
              "d43a5d2dae1573e03dec545a2103f1bc61a3e0d6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ghr/
mkdir -p ${bindir}
go build -o ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("ghr", :ghr),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :go])
