using BinaryBuilder

name = "Datamonger"
version = v"0.3.1"

sources = [GitSource(
    "https://github.com/jolars/datamonger.git",
    "8c5aa5bad6b4efae540542312ef33fd4f7e99c98";
    tag = "datamonger-ffi-v$(version)",
)]

script = raw"""
cd ${WORKSPACE}/srcdir/datamonger/crates/datamonger-ffi

# Rust defaults to a static C runtime on musl, which prevents cdylib builds.
if [[ "${target}" == *-musl* ]]; then
    export RUSTFLAGS="${RUSTFLAGS} -C target-feature=-crt-static"
fi

cargo build --release --locked --target=${rust_target} --target-dir target
install -Dvm755 target/${rust_target}/release/*datamonger_ffi.${dlext} ${libdir}/datamonger_ffi.${dlext}
install -Dvm644 include/datamonger.h ${includedir}/datamonger.h
install_license ../../LICENSE
"""

platforms = supported_platforms()
# CompilerSupportLibraries_jll 1.0.5 has no RISC-V artifacts.
filter!(p -> arch(p) != "riscv64", platforms)
# CompilerSupportLibraries_jll 1.0.5 has no aarch64 FreeBSD artifact.
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)

products = [
    LibraryProduct("datamonger_ffi", :libdatamonger_ffi),
]

# The Rust library links to libgcc_s for unwinding on glibc Linux.
dependencies = [Dependency("CompilerSupportLibraries_jll"; compat = "1.0.5")]

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    compilers = [:c, :rust],
    julia_compat = "1.10",
)
