using BinaryBuilder

name = "vegafusion"
version = v"0.0.4"

sources = [
    GitSource("https://github.com/vegafusion/vegafusion.git",
                  "c0927268fc7544878c58a606e01503ba3fed615e"),
]

# Bash recipe for building across all platforms
script = raw"""
export TARGET_CC=$CC

cd ${WORKSPACE}/srcdir/vegafusion/vegafusion-server/
cargo build --release
mkdir -p "${bindir}"
cp "../target/${rust_target}/release/vegafusion-server${exeext}" "${bindir}/."
install_license ../LICENSE
"""

platforms = supported_platforms()
# Our Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# Build fails with error 'BinaryBuilder: Cannot force an architecture via -march'
# while compiling c code in https://github.com/briansmith/ring dependency
filter!(p -> arch(p) ∉ ("armv6l", "armv7l", "i686"), platforms)

# PowerPC not supported https://github.com/briansmith/ring/issues/389
filter!(p -> arch(p) != "powerpc64le", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("vegafusion-server", :vegafusionserver),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.6")
