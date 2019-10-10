using BinaryBuilder, Pkg.Artifacts

include("../common.jl")

name = "MegaRust"
version = v"1.18.3"

sources = [
    # TODO: Switch to musl once https://github.com/rust-lang/rustup.rs/pull/1882 is released
    "https://static.rust-lang.org/rustup/archive/$(version)/x86_64-unknown-linux-gnu/rustup-init" =>
    "a46fe67199b7bcbbde2dcbc23ae08db6f29883e260e23899a88b9073effc9076",
]

# The first thing we're going to do is to install Rust for all targets into a single prefix
script = raw"""
cd ${WORKSPACE}/srcdir

# We reinstall RustBase because that's easier than re-using it
export CARGO_HOME=${prefix}
export RUSTUP_HOME=${prefix}
mv *-rustup-init rustup-init
chmod +x rustup-init
./rustup-init -y --no-modify-path --default-host=${rust_host}

# Collection of all rust targets we will download toolchains for:
RUST_TARGETS=(
    aarch64-unknown-linux-gnu
    aarch64-unknown-linux-musl
    armv7-unknown-linux-gnueabihf
    armv7-unknown-linux-musleabihf
    i686-unknown-linux-gnu
    i686-unknown-linux-musl
    x86_64-unknown-linux-gnu
    x86_64-unknown-linux-musl
    powerpc64le-unknown-linux-gnu
    i686-pc-windows-gnu
    x86_64-pc-windows-gnu
    x86_64-apple-darwin
    x86_64-unknown-freebsd
)

for rust_target in "${RUST_TARGETS[@]}"; do
    # Install our target-specific stuffs
    ${CARGO_HOME}/bin/rustup target add ${rust_target}
done

# We're going to bundle cargo-edit since it's a useful dep
export OPENSSL_STATIC=yes
${CARGO_HOME}/bin/cargo install cargo-edit
"""

# We assemble this giant tarball, then will split it up immediately after this:
platforms = [Linux(:x86_64; libc=:glibc)]
products = [
    ExecutableProduct("cargo", :cargo),
]
dependencies = [
    "OpenSSL_jll",
]
build_info = build_tarballs(ARGS, "MegaRust", version, sources, script, platforms, products, dependencies; skip_audit=true)

# We don't actually need the .tar.gz it creates, so delete that to save space
rm(joinpath("products", first(values(build_info))[1]))

# Take the hash of the unpacked MegaRust artifact, then split it into a bunch of smaller ones
mega_rust_path = artifact_path(first(values(build_info))[3])
rust_host = Linux(:x86_64; libc=:glibc)
rust_host_triplet = BinaryBuilder.map_rust_target(rust_host)

for target_platform in supported_platforms()
    rust_target_triplet = BinaryBuilder.map_rust_target(target_platform)
    @info("Generating artifacts for $(rust_target_triplet)...")
    unpacked_hash = create_artifact() do dir
        srcpath = joinpath(mega_rust_path, "toolchains", "stable-$(rust_host_triplet)", "lib", "rustlib", rust_target_triplet)
        dstpath = joinpath(dir, "toolchains", "stable-$(rust_host_triplet)", "lib", "rustlib")
        mkpath(dstpath)
        cp(srcpath, joinpath(dstpath, rust_target_triplet))
    end
    squashfs_hash = unpacked_to_squashfs(unpacked_hash, "RustToolchain", version; platform=rust_host, target=target_platform)

    # Upload them both to GH releases on Yggdrasil
    upload_and_insert_shards("JuliaPackaging/Yggdrasil", "RustToolchain", version, unpacked_hash, squashfs_hash, rust_host; target=target_platform)
end

# Finally, we do RustBase:
unpacked_hash = create_artifact() do dir
    cp(joinpath(mega_rust_path, "bin"), joinpath(dir, "bin"))
    cp(joinpath(mega_rust_path, "toolchains"), joinpath(dir, "toolchains"))
    rm(joinpath(dir, "toolchains", "stable-$(rust_host_triplet)", "share"); recursive=true)
    rm(joinpath(dir, "toolchains", "stable-$(rust_host_triplet)", "etc"); recursive=true)
    for rust_target_triplet in BinaryBuilder.map_rust_target.(supported_platforms())
        rm(joinpath(dir, "toolchains", "stable-$(rust_host_triplet)", "lib", "rustlib", rust_target_triplet); recursive=true)
    end

    # Also generate "config" file for Cargo where we give it the linkers for all our targets
    open(joinpath(dir, "config"), "w") do io
        write(io, """
        # Configuration file for `cargo`
        """)
        for platform in supported_platforms()
            write(io, """
            [target.$(BinaryBuilder.map_rust_target(platform))]
            linker = "$(triplet(platform))-gcc"
            """)
        end
    end
end

squashfs_hash = unpacked_to_squashfs(unpacked_hash, "RustBase", version; platform=rust_host)
upload_and_insert_shards("JuliaPackaging/Yggdrasil", "RustBase", version, unpacked_hash, squashfs_hash, rust_host)
