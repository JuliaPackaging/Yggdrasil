# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cargo_license"
version = v"0.4.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/onur/cargo-license.git", "f489e18b0fc45ab31d9766841e7f551e96ee6a8c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cargo-license
cargo build --release --all
mkdir ${bindir}
cp target/${rust_target}/release/cargo-license${exeext} ${bindir}/
install_license $WORKSPACE/srcdir/cargo-license/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("cargo-license", :cargo_license),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
                compilers=[:c, :rust], julia_compat="1.6")
