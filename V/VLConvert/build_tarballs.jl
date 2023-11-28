using BinaryBuilder

name = "VLConvert"
version = v"1.1.0"

sources = [
    ArchiveSource("https://github.com/vega/vl-convert/archive/refs/tags/v$(version).tar.gz",
                  "e409cd8c2b2b90e8be13e3bec41482c07b03b2e3a1dc6afe715d5a6968b13b2a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/vl-convert*/
cargo build --release
install -D -m 755 "target/${rust_target}/release/vl-convert${exeext}" "${bindir}/vl-convert${exeext}"
"""

platforms = supported_platforms()
# Our Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("vl-convert", :vlconvert),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust])
