using BinaryBuilder, Pkg.BinaryPlatforms

include("../common.jl")

name = "RustBase"
version = v"1.18.3"

sources = [
    # TODO: Switch to musl once https://github.com/rust-lang/rustup.rs/pull/1882 is released
    "https://static.rust-lang.org/rustup/archive/$(version)/x86_64-unknown-linux-gnu/rustup-init" =>
    "a46fe67199b7bcbbde2dcbc23ae08db6f29883e260e23899a88b9073effc9076",
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir

export CARGO_HOME=${prefix}
export RUSTUP_HOME=${prefix}
mv *-rustup-init rustup-init
chmod +x rustup-init
./rustup-init -y --no-modify-path --default-host=${rust_host}

# Kill toolchains and update-hashes, we'll let that live inside of `RustToolchain`
rm -rf ${prefix}/toolchains
rm -rf ${prefix}/update-hashes
"""

# We only build for Linux x86_64
platforms = [
    Linux(:x86_64; libc=:musl),
]

# Dependencies that must be installed before this package can be built
dependencies = []

# The products that we will ensure are always built
products = [
    ExecutableProduct("rustup", :rustup),
    ExecutableProduct("rustc", :rustc),
    ExecutableProduct("cargo", :cargo),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_info = build_tarballs(ARGS, "$(name)", version, sources, script, platforms, products, dependencies; skip_audit=true)

upload_and_insert_shards("JuliaPackaging/Yggdrasil", name, version, build_info)
