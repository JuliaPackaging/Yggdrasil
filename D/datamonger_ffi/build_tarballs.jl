using BinaryBuilder

name = "datamonger_ffi"
version = v"0.2.0"

sources = [GitSource(
    "https://github.com/jolars/datamonger.git",
    "3fbd8cd83ec2b3ee55e277096e1f575ae9795e54";
    tag = "datamonger-ffi-v$(version)",
)]

script = raw"""
cd ${WORKSPACE}/srcdir/datamonger/crates/datamonger-ffi

# Rust defaults to a static C runtime on musl, which prevents cdylib builds.
if [[ "${target}" == *-musl* ]]; then
    export RUSTFLAGS="${RUSTFLAGS} -C target-feature=-crt-static"
fi

cargo build --release --locked --target=${rust_target}
install -Dvm755 target/${rust_target}/release/*datamonger_ffi.${dlext} -t ${libdir}
install -Dvm644 include/datamonger.h ${includedir}/datamonger.h
install_license ../../LICENSE
"""

platforms = supported_platforms()

products = [
    LibraryProduct(["libdatamonger_ffi", "datamonger_ffi"], :libdatamonger_ffi),
    FileProduct("include/datamonger.h", :datamonger_h),
]

dependencies = [Dependency("CompilerSupportLibraries_jll"; compat = "1.1.2")]

# CompilerSupportLibraries 1.1.2 artifacts use the libgfortran5 platform tag.
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
    preferred_rust_version = v"1.97.0",
    preferred_gcc_version = v"8",
    julia_compat = "1.10",
)
