using BinaryBuilder

name = "WolframAppDiscovery"
version = v"0.4.3"

sources = [
    GitSource("https://github.com/WolframResearch/wolfram-app-discovery-rs.git", "aa6feb10261593d7c6f13062f7f68b47a8b130b8")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/wolfram-app-discovery-rs/
cargo build --release --bin wolfram-app-discovery --features=cli
install -Dvm 755 "target/${rust_target}/release/wolfram-app-discovery${exeext}" "${bindir}/wolfram-app-discovery${exeext}"
install_license LICENSE-MIT LICENSE-APACHE
"""

platforms = supported_platforms()
# Our Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("wolfram-app-discovery", :wolfram_app_discovery),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.6")
