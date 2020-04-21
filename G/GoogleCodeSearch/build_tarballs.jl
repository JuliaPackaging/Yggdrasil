# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GoogleCodeSearch"
version = v"1.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/google/codesearch.git", "8ba29bd255b740aee4eb4e4ddb5d7ec0b4d9f23e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
install_license codesearch/LICENSE
mkdir gsc
cd gsc
go mod init github.com/m
go get -d -v github.com/google/codesearch@v1.2.0
mkdir -p "${bindir}"
go build -o "${bindir}/csearch${exeext}" github.com/google/codesearch/cmd/csearch
go build -o "${bindir}/cindex${exeext}" github.com/google/codesearch/cmd/cindex
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("csearch", :csearch),
    ExecutableProduct("cindex", :cindex)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers = [:go, :c])
