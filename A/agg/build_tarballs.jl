using BinaryBuilder

name = "agg"
version = v"1.4.3"

sources = [
    GitSource("https://github.com/asciinema/agg", "84ef0590c9deb61d21469f2669ede31725103173")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/agg/
mkdir -p ${bindir}
cargo build --release
install_license LICENSE
install -Dvm 755 "target/${rust_target}/release/agg${exeext}" "${bindir}/agg${exeext}"
"""

# We build for a restricted set of platforms, because our rust toolchain is a little broken
platforms = supported_platforms()

# error: failed to run custom build command for `ring v0.16.20`
filter!(p -> arch(p) != "i686", platforms)
filter!(p -> arch(p) != "armv7l", platforms)
filter!(p -> arch(p) != "armv6l", platforms)
filter!(p -> arch(p) != "powerpc64le", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("agg", :agg),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.6")
