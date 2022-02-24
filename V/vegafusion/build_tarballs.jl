using BinaryBuilder

name = "vegafusion"
version = v"0.0.1"

sources = [
    GitSource("https://github.com/vegafusion/vegafusion.git",
                  "c0927268fc7544878c58a606e01503ba3fed615e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/vegafusion-server/
cargo build --release
mkdir -p "${libdir}"
cp "target/${rust_target}/release/libvegafusion-server.${dlext}" "${libdir}/."
install_license LICENSE
"""

platforms = supported_platforms()
# Our Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libvegafusion-server", :libvegafusionserver),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.6")
