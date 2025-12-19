using BinaryBuilder, Pkg

name = "libsparseir"
version = v"0.7.3"

# Collection of sources required to complete build
sources = [
    # sparse-ir-rs v0.7.3
    GitSource(
        "https://github.com/SpM-lab/sparse-ir-rs.git",
        "594143f902ff2fe7371af0962591728898b67a75",
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/sparse-ir-rs/
install_license LICENSE

if [[ "${target}" == *mingw* ]]; then
    export RUSTFLAGS="-C link-arg=-L${libdir} -C link-arg=-lblastrampoline-5"
    cargo build --release --features system-blas
    install -D -m 755 "target/${rust_target}/release/sparse_ir_capi.${dlext}" \
        "${libdir}/libsparse_ir_capi.${dlext}"
else
    export RUSTFLAGS="-C link-arg=-lblastrampoline"
    cargo build --release --features system-blas
    install -D -m 755 "target/${rust_target}/release/libsparse_ir_capi.${dlext}" \
        "${libdir}/libsparse_ir_capi.${dlext}"
fi

cp sparse-ir-capi/include/sparseir/sparseir.h ${includedir}
"""

platforms = supported_platforms()
# Build fails: deployment target in MACOSX_DEPLOYMENT_TARGET was set to 10.10, but the minimum supported by `rustc` is 10.12
filter!(p -> !(arch(p) == "x86_64" && os(p) == "macos"), platforms)
# Build fails: warning: dropping unsupported crate type `cdylib` for target `aarch64-unknown-linux-musl`
filter!(p -> !(arch(p) == "aarch64" && os(p) == "linux" && libc(p) == "musl"), platforms)
# Build fails: Couldn't open /proc/mounts
filter!(p -> !(arch(p) == "x86_64" && os(p) == "linux" && libc(p) == "musl"), platforms)
# Build fails: ERROR: LoadError: Requested Rust toolchain 1.87.0 not available on platform aarch64-unknown-freebsd
filter!(p -> !(arch(p) == "aarch64" && os(p) == "freebsd"), platforms)
# Build fails: warning: dropping unsupported crate type `cdylib` for target `arm-unknown-linux-musleabihf`
filter!(p -> !(arch(p) == "armv6l"), platforms)
# Build fails: warning: dropping unsupported crate type `cdylib` for target `armv7-unknown-linux-musleabihf`
filter!(p -> !(arch(p) == "armv7l"), platforms)
# Build fails: error: IP-relative addressing requires 64-bit mode
filter!(p -> !(arch(p) == "i686"), platforms)
# Build fails: ERROR: LoadError: Requested Rust toolchain 1.87.0 not available on platform riscv64-linux-gnu
filter!(p -> !(arch(p) == "riscv64"), platforms)

products = [
    LibraryProduct("libsparse_ir_capi", :libsparseir),
]

dependencies = [
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.10", compilers=[:c, :rust])
