# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenPolicyAgent"
version = v"1.5.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/open-policy-agent/opa.git", "5421c8e5ae31a15b4e129688b85ffc4e814cdb63"),
    GitSource("https://github.com/josephspurrier/goversioninfo", "53cb51b8aa6b6b62ab8196e66a766ea7598c67fa"),
]

# Bash recipe for building across all platforms
script = raw"""
# opa requires goversioninfo if building for Windows
# it uses this tool as part of the build process so we need to build it for linux, not windows
# however the BB go wrapper script sets windows in it, so we have to use the underlying go command
if [[ "${target}" == *-w64-* ]]; then
    cd $WORKSPACE/srcdir/goversioninfo/
    GOOS=linux GOEXE="" GOARCH=amd64 /opt/x86_64-linux-musl/go/bin/go install ./cmd/goversioninfo
    export PATH=$PATH:$GOPATH/bin
fi

cd $WORKSPACE/srcdir/opa/
CGO_ENABLED=0 WASM_ENABLED=0 make build
mkdir -p $bindir
install -Dvm 755 opa_* $bindir/opa${exeext}
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("opa", :opa)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:go, :c])
