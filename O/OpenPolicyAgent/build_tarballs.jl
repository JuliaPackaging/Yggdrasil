# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OpenPolicyAgent"
version = v"0.69.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/open-policy-agent/opa.git", "4a3fd1a715a8d24d102719421931020aafa8b778")
]

# Bash recipe for building across all platforms
script = raw"""
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
