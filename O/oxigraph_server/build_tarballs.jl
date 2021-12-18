# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oxigraph_server"
version = v"0.2.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/oxigraph/oxigraph.git", "a21dcbb4f7355d7a00a86fbc5ad2c350a53629c4"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/oxigraph/server

# export OPENSSL_STATIC=yes

cargo build --release --no-default-features --features=sled

cargo install cargo-license


cargo-license --avoid-build-deps --avoid-dev-deps --json > CARGO_LICENSES.json

install_license CARGO_LICENSES.json $WORKSPACE/srcdir/oxigraph/LICENSE-MIT $WORKSPACE/srcdir/oxigraph/LICENSE-APACHE

cp ../target/${rust_target}/release/oxigraph_server${exeext} ${bindir}/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("oxigraph_server", :oxigraph_server),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("OpenSSL_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
                compilers=[:c, :rust], preferred_gcc_version=v"7", lock_microarchitecture=false, julia_compat="1.6")
