# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase

name = "bat"
version = v"13.0.0"

# Collection of sources required to complete build
#
sources = [
    GitSource(
        "https://github.com/sharkdp/bat.git",
        "25f4f96ea3afb6fe44552f3b38ed8b1540ffa1b3"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/bat
cargo build --locked --release
mkdir -p "${bindir}"
cp "target/${rust_target}/release/bat${exeext}" "${bindir}/."
install_license LICENSE-MIT LICENSE-APACHE NOTICE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("bat", :bat),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust])
