using BinaryBuilder, Pkg.BinaryPlatforms

include("../common.jl")

compiler_target = platform_key_abi(ARGS[end])
if isa(compiler_target, UnknownPlatform)
    error("This is not a typical build_tarballs.jl!  Must provide exactly one platform as the last argument!")
end
deleteat!(ARGS, length(ARGS))
name = "Rust"
version = v"1.18.3"

sources = [
    # TODO: Switch to musl once https://github.com/rust-lang/rustup.rs/pull/1882 is released
    "https://static.rust-lang.org/rustup/archive/$(version)/x86_64-unknown-linux-gnu/rustup-init" =>
    "a46fe67199b7bcbbde2dcbc23ae08db6f29883e260e23899a88b9073effc9076",
]

# Bash recipe for building across all platforms
script = "COMPILER_TARGET=$(triplet(compiler_target))\n"
script *= raw"""
cd ${WORKSPACE}/srcdir

# Map our target names to cargo-compatible ones
rust_target()
{
    if [[ "$1" == x86_64-apple-darwin* ]]; then
        echo x86_64-apple-darwin
    elif [[ "$1" == x86_64-unknown-freebsd* ]]; then
        echo x86_64-unknown-freebsd
    elif [[ "$1" == x86_64-*mingw* ]]; then
        echo x86_64-pc-windows-gnu
    elif [[ "$1" == i686-*mingw* ]]; then
        echo i686-pc-windows-gnu
    elif [[ "$1" == *linux* ]]; then
        echo "$1" | sed -E 's/([^\\-]+)-(.+)/\1-unknown-\2/'
    else
        echo "Can't map $1 to a rust-compatible target string!"
        exit 1
    fi
}

export CARGO_HOME=${prefix}
export RUSTUP_HOME=${prefix}
mv *-rustup-init rustup-init
chmod +x rustup-init
./rustup-init -y --no-modify-path --default-host=$(rust_target "${COMPILER_TARGET}") 
"""

# We only build for Linux x86_64
platforms = [
    # TODO: Switch to musl once https://github.com/rust-lang/rustup.rs/pull/1882 is released
    Linux(:x86_64; libc=:glibc),
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
build_info = build_tarballs(ARGS, "$(name)-$(triplet(compiler_target))", version, sources, script, platforms, products, dependencies; skip_audit=true)

upload_and_insert_shards("JuliaPackaging/Yggdrasil", name, version, build_info; target=compiler_target)
