using BinaryBuilder

name = "Eunoia"
version = v"1.10.1"

sources = [GitSource(
    "https://github.com/jolars/eunoia.git",
    "e818b339bde8a91db656393e09575d5640663447";
    tag = "v$(version)",
)]

script = raw"""
cd ${WORKSPACE}/srcdir/eunoia*

if [[ "${target}" == *-musl* ]]; then
    # Rust defaults to a static C runtime on musl, which prevents building a cdylib.
    export RUSTFLAGS="${RUSTFLAGS} -C target-feature=-crt-static"
fi

cargo build --release --locked --package eunoia-capi --target ${rust_target} -j${nproc}
install -Dvm 755 target/${rust_target}/release/*eunoia_capi.${dlext} -t ${libdir}
install_license LICENSE-MIT LICENSE-APACHE
"""

platforms = supported_platforms()
# The i686 Windows toolchain disables unwinding, which the C API needs to catch panics.
filter!(p -> !(Sys.iswindows(p) && nbits(p) == 32), platforms)

products = [LibraryProduct(["libeunoia_capi", "eunoia_capi"], :libeunoia_capi)]

dependencies = [Dependency("CompilerSupportLibraries_jll"; compat = "1.3.1")]

# GCC 8 selects the libgfortran5 artifacts provided by CompilerSupportLibraries.
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
    preferred_gcc_version = v"8",
    julia_compat = "1.10",
)
