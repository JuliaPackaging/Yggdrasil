using BinaryBuilder

name = "github_release"
version = v"0.11.0"

# Collection of sources required to build github_release
sources = [
    GitSource("https://github.com/github-release/github-release", "fd5c623f87a849917af4e6a0eca43ec7db9b1bb6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/github-release*
mkdir -p ${bindir}
go build -o ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("github-release", :github_release),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               compilers=[:c, :go], julia_compat="1.6")
