using BinaryBuilder

name = "VegaFusion"
version = v"0.3.0"

sources = [
    GitSource("https://github.com/vegafusion/vegafusion.git",
              "42606e505364beacd30452cbe76744cf0a7428c4"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/vegafusion/vegafusion-server/
cargo build --release
install -Dm 755 "../target/${rust_target}/release/vegafusion-server${exeext}" "${bindir}/vegafusion-server${exeext}"
"""

platforms = supported_platforms()
# Our Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# i686 Linux currently blocked by "undefined reference to `__atomic_load'" eror, see https://github.com/vegafusion/vegafusion/issues/92
filter!(p -> !(Sys.islinux(p) && (arch(p) == "i686")), platforms)


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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.6", lock_microarchitecture=false)
