using BinaryBuilder

include(joinpath(@__DIR__, "../../platforms/macos_sdks.jl"))

name = "LanceDB_C"
# Use the package version from upstream Cargo.toml at the source commit below.
version = v"0.33.0"

sources = [
    GitSource("https://github.com/lancedb/lancedb-c.git",
              "a4ac1c0343a8959cfc5b3d462c640b4d3b09c8dd"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/lancedb-c

install_license LICENSE

export PROTOC="${host_bindir}/protoc"
export CC_$(echo ${rust_host} | tr '-' '_')="${CC_BUILD}"
export CXX_$(echo ${rust_host} | tr '-' '_')="${CXX_BUILD}"

if [[ "${target}" == *-musl* ]]; then
    export RUSTFLAGS="${RUSTFLAGS} -C target-feature=-crt-static"
fi

cargo rustc --release --locked --lib --crate-type=cdylib --target=${rust_target}
install -Dvm755 "target/${rust_target}/release/*lancedb.${dlext}" -t "${libdir}"
install -Dvm644 include/lancedb.h "${includedir}/lancedb.h"
"""

# The default Intel macOS SDK lacks utimensat and SecTrustEvaluateWithError,
# required by xet-runtime and security-framework, respectively.
sources, script = require_macos_sdk("11.1", sources, script; deployment_target="10.15")

platforms = supported_platforms()
# Exclude targets where gearhash uses unavailable x86-64 intrinsics (i686),
# io-uring's prebuilt bindings are incompatible (ARM32), or lance-core lacks
# a SIMD detection fallback (PowerPC/RISC-V).
filter!(p -> arch(p) in ("x86_64", "aarch64"), platforms)
# lance-core's AArch64 CPU detection module is missing on FreeBSD.
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)

products = [
    LibraryProduct(["liblancedb", "lancedb"], :liblancedb),
    FileProduct("include/lancedb.h", :lancedb_h),
]

dependencies = [
    HostBuildDependency("protoc_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    compilers=[:c, :rust], preferred_rust_version=v"1.97.0",
    preferred_gcc_version=v"12.1.0", julia_compat="1.6",
    # lance-linalg compiles ISA-specific SIMD kernels and selects them at runtime.
    # Allow the upstream build to set per-kernel architecture flags.
    lock_microarchitecture=false)
