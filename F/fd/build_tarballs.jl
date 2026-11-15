# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase

name = "fd"
version = v"10.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sharkdp/fd", "d38148f0aabdd073b4080cde770f679f3197b920"; tag="v$(version)"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/fd
cargo build --release --locked
install -Dvm 755 "target/${rust_target}/release/fd${exeext}" -t "${bindir}"
install_license LICENSE-APACHE LICENSE-MIT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("fd", :fd_executable),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a build.jl file as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust], lock_microarchitecture=false)
