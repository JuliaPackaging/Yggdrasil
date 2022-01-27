using BinaryBuilder

name = "vegafusion"
version = v"0.0.1"

sources = [
    GitSource("https://github.com/vegafusion/vegafusion.git",
                  "4f261d0aea9eaf1c220de29c5f396d95025e4af2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/vegafusion/vegafusion-core/
cargo build --release
cp "target/${rust_target}/release/vegafusion-core${exeext}" "${bindir}/."
install_license ../LICENSE
"""

platforms = supported_platforms()
# Our Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("vegafusion-core", :vegafusioncore),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.6")
