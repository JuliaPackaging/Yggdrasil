# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "cbindgen"
version = v"0.22.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/eqrion/cbindgen/archive/refs/tags/v$(version).tar.gz",
                  "f129b453df9d84e6d098a446f928961241b2a0edc29f827addca154049dcc434"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cbindgen*/
cargo build --release
install -Dvm 755 "target/${rust_target}/release/cbindgen${exeext}" "${bindir}/cbindgen${exeext}"
"""

# Our Rust toolchain for i686 is unusable.
platforms = supported_platforms(; exclude=p -> Sys.iswindows(p) && arch(p) == "i686")

# The products that we will ensure are always built
products = [
    ExecutableProduct("cbindgen", :cbindgen),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust])
