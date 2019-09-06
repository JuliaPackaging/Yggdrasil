using BinaryBuilder, Pkg.BinaryPlatforms

include("../common.jl")

name = "Go"
version = v"1.13"

sources = [
    "https://dl.google.com/go/go1.13.linux-amd64.tar.gz" =>
    "68a2297eb099d1a76097905a2ce334e3155004ec08cdea85f24527be3c48e856",
]

# Bash recipe for building across all platforms
script = raw"""
mv ${WORKSPACE}/srcdir/go ${prefix}/
"""

# We only build for Linux x86_64
platforms = [
    # TODO: Switch to musl once https://github.com/rust-lang/rustup.rs/pull/1882 is released
    Linux(:x86_64; libc=:musl),
]

# Dependencies that must be installed before this package can be built
dependencies = []

# The products that we will ensure are always built
products = [
    ExecutableProduct("go", :go, "go/bin"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_info = build_tarballs(ARGS, "$(name)", version, sources, script, platforms, products, dependencies; skip_audit=true)

upload_and_insert_shards("JuliaPackaging/Yggdrasil", name, version, build_info)
