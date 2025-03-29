using BinaryBuilder

name = "keyringcli"
upstream_version = v"3.6.2"
version = VersionNumber(
    upstream_version.major,
    upstream_version.minor,
    upstream_version.patch * 100 + 0,
)

sources = [
    GitSource(
        "https://github.com/open-source-cooperative/keyring-rs.git",
        "ee3f80d0d386a03145d20beea076b172e60f95af"
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/keyring-rs/

# Print Rust version and target info for debugging
rustc --version
echo "Building for target: ${rust_target}"

# Build only the CLI example with verbose output
cargo build -v --release --example keyring-cli

# Install the CLI example binary
install -D -m 755 "target/${rust_target}/release/examples/cli${exeext}" "${bindir}/keyring-cli${exeext}"

install_license LICENSE-MIT LICENSE-APACHE
"""

platforms = supported_platforms()
# Our Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("keyring-cli", Symbol("keyring-cli")),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers = [:c, :rust], julia_compat = "1.6")
