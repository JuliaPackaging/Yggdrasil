using BinaryBuilder

name = "github_release"
version = v"0.10.0"

# Collection of sources required to build github_release
sources = [
    ArchiveSource("https://github.com/github-release/github-release/archive/refs/tags/v$(version).zip",
                  "369fc1ccdf9e0250b1974cd1089c71f994e12f29d9524205a16d1a2c29364396"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/github-release*
mkdir -p ${bindir}
go mod init github-release
go mod tidy
go mod vendor
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :go])
