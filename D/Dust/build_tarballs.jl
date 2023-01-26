# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase

name = "Dust"
version = v"0.8.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/bootandy/dust/archive/refs/tags/v$(version).tar.gz",
                  "1e07203546274276503a4510adcf5dc6eacd5d1e20604fcd55a353b3b63c1213"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/dust*/
cargo build --release
install -Dvm 755 "target/${rust_target}/release/dust${exeext}" "${bindir}/dust${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("dust", :dust),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust])
