### Instructions for adding a new version of the Rust toolchain
#
# * update the `version` variable
# * To deploy the shard and automatically update your BinaryBuilderBase's
#   `Artifacts.toml`, use the `--deploy` flag to the `build_tarballs.jl` script.
#   You can build & deploy by running:
#
#      julia build_tarballs.jl --debug --verbose --deploy
#

using BinaryBuilderBase, BinaryBuilder, Pkg.Artifacts
using BinaryBuilderBase: map_rust_target

include("../common.jl")

# We first download Rustup, and use that to install rust
rustup_name = "RustStage1"
# NOTE: we can't update to newer versions because of
# <https://github.com/rust-lang/rustup/issues/3116>.
rustup_version = v"1.24.3"

# This is the version of the Rust toolchain we install
version = v"1.83.0"

sources = [
    # We'll use rustup to install rust
    FileSource("https://static.rust-lang.org/rustup/archive/$(rustup_version)/x86_64-unknown-linux-musl/rustup-init",
               "bdf022eb7cba403d0285bb62cbc47211f610caec24589a72af70e1e900663be9"),
]

# Check if deploy flag is set
deploy = "--deploy" in ARGS

# The first thing we're going to do is to install Rust for all targets into a single prefix
script = "version=$(version)\n" * raw"""
cd ${WORKSPACE}/srcdir

# We reinstall RustBase because that's easier than re-using it
export CARGO_HOME=${prefix}
export RUSTUP_HOME=${prefix}
chmod +x rustup-init
./rustup-init -y --no-modify-path --default-host=${rust_host} --default-toolchain ${version}

# Collection of all rust targets we will download toolchains for:
RUST_TARGETS=(
    aarch64-apple-darwin
    # aarch64-unknown-freebsd   # toolchain is not available
    aarch64-unknown-linux-gnu
    aarch64-unknown-linux-musl
    arm-unknown-linux-gnueabihf
    arm-unknown-linux-musleabihf
    armv7-unknown-linux-gnueabihf
    armv7-unknown-linux-musleabihf
    i686-pc-windows-gnu
    i686-unknown-linux-gnu
    i686-unknown-linux-musl
    powerpc64le-unknown-linux-gnu
    # riscv64-unknown-linux-gnu   # toolchain is not available
    x86_64-apple-darwin
    x86_64-pc-windows-gnu
    x86_64-unknown-freebsd
    x86_64-unknown-linux-gnu
    x86_64-unknown-linux-musl
)

for rust_target in "${RUST_TARGETS[@]}"; do
    # Install our target-specific stuffs for the toolchain we're requesting
    ${CARGO_HOME}/bin/rustup target add --toolchain ${version} ${rust_target}
done

# We're going to bundle cargo-edit since it's a useful dep
export OPENSSL_STATIC=yes
${CARGO_HOME}/bin/cargo install cargo-edit
"""

# We assemble this giant tarball, then will split it up immediately after this:
platforms = [Platform("x86_64", "linux"; libc="musl")]
products = [
    ExecutableProduct("cargo", :cargo),
]
dependencies = [
    Dependency("OpenSSL_jll"; compat="3.0.15"),
]
ndARGS = filter(a -> !occursin("--deploy", a), ARGS)
build_info = build_tarballs(ndARGS, rustup_name, rustup_version, sources, script, platforms, products, dependencies; skip_audit=true)

# We don't actually need the .tar.gz it creates, so delete that to save space
rm(joinpath("products", first(values(build_info))[1]))

# Take the hash of the unpacked Rustup artifact, then split it into a bunch of smaller ones
mega_rust_path = artifact_path(first(values(build_info))[3])
rust_host = Platform("x86_64", "linux"; libc="musl")
rust_host_triplet = map_rust_target(rust_host)

rust_platforms = supported_platforms()
# Skip unsupported platforms (see `RUST_TARGETS` above)
filter!(p -> !(arch(p) == "aarch64" && Sys.isfreebsd(p)), rust_platforms)
filter!(p -> !(arch(p) == "riscv64"), rust_platforms)

for target_platform in rust_platforms
    rust_target_triplet = map_rust_target(target_platform)
    @info("Generating artifacts for $(rust_target_triplet)...")
    unpacked_hash = create_artifact() do dir
        srcpath = joinpath(mega_rust_path, "toolchains", "$(version)-$(rust_host_triplet)", "lib", "rustlib", rust_target_triplet)
        dstpath = joinpath(dir, "toolchains", "$(version)-$(rust_host_triplet)", "lib", "rustlib")
        mkpath(dstpath)
        cp(srcpath, joinpath(dstpath, rust_target_triplet))

        # Our mingw rust shards need to have their crt2.o updated
        # https://github.com/rust-lang/rust/issues/48272#issuecomment-429596397
        if Sys.iswindows(target_platform)
            # Find the corresponding mingw toolchain within a GCC shard
            all_cs = BinaryBuilderBase.all_compiler_shards()
            cs = first(filter(cs -> cs.name == "GCCBootstrap" && cs.target == target_platform && cs.archive_type == :unpacked, all_cs))
            cs_path = BinaryBuilderBase.mount(cs, "")

            # Locate our GCC's mingw's crt2.o
            crt_src = joinpath(cs_path, triplet(target_platform), "sys-root", "lib", "crt2.o")
            # Overwrite the one that rust ships with
            crt_dst = joinpath(dstpath, rust_target_triplet, "lib", "crt2.o")
            cp(crt_src, crt_dst; force=true)
        end
    end
    squashfs_hash = unpacked_to_squashfs(unpacked_hash, "RustToolchain", version; platform=rust_host, target=target_platform)

    # Upload them both to GH releases on Yggdrasil
    if deploy
        upload_and_insert_shards("JuliaPackaging/Yggdrasil", "RustToolchain", version, unpacked_hash, squashfs_hash, rust_host; target=target_platform)
    end
end

# Finally, we do RustBase:
unpacked_hash = create_artifact() do dir
    cp(joinpath(mega_rust_path, "bin"), joinpath(dir, "bin"))
    cp(joinpath(mega_rust_path, "toolchains"), joinpath(dir, "toolchains"))
    rm(joinpath(dir, "toolchains", "$(version)-$(rust_host_triplet)", "share"); recursive=true)
    rm(joinpath(dir, "toolchains", "$(version)-$(rust_host_triplet)", "etc"); recursive=true)
    for rust_target_triplet in map_rust_target.(rust_platforms)
        rm(joinpath(dir, "toolchains", "$(version)-$(rust_host_triplet)", "lib", "rustlib", rust_target_triplet); recursive=true)
    end
end

squashfs_hash = unpacked_to_squashfs(unpacked_hash, "RustBase", version; platform=rust_host)

if deploy
    upload_and_insert_shards("JuliaPackaging/Yggdrasil", "RustBase", version, unpacked_hash, squashfs_hash, rust_host)
end
