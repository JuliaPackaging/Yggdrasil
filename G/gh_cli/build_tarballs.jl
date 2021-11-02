# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gh_cli"
version = v"2.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/cli/cli.git", "a843cbd72813025817a2293a09b31c4597a3f655"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cli/

export GO_LDFLAGS="-s -w"
export CGO_ENABLED=0

if [[ "${target}" == *-apple-* ]]; then
    export GOARCH=darwin
fi

if [[ "${target}" == aarch64* ]]; then
    export GOARCH=arm
fi

if [[ "${target}" == x86_64-* ]]; then
    export GOARCH=amd64
fi

export CGO_ENABLED=0
make clean bin/gh
mkdir ${bindir}
mv ./bin/gh ${bindir}/gh${exeext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    ExecutableProduct("gh", :gh)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:go, :c])
