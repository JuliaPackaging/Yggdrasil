using BinaryBuilder

name = "ghr"
version = v"0.16.2"

# Collection of sources required to build ghr
sources = [
    GitSource("https://github.com/tcnksm/ghr.git",
              "ac9295b8f6806b04d18e543f469821cbd0e0c1ef"),
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
