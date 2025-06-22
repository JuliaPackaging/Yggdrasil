using BinaryBuilder

name = "ghr"
version = v"0.17.0"

# Collection of sources required to build ghr
sources = [
    GitSource("https://github.com/tcnksm/ghr.git",
              "f7dfff6686917eaa749c7a01660a82e55528df2f"),
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :go], julia_compat = "1.6")
