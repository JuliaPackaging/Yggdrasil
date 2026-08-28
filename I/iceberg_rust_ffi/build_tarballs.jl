using BinaryBuilder

name = "iceberg_rust_ffi"
version = v"0.9.2"

sources = [
    GitSource("https://github.com/RelationalAI/RustyIceberg.jl.git", "208160ac5b133b771d4520970165cc16bcae994b"),
]

# Bash recipe for building across all platforms
script = raw"""
if [[ "${target}" == aarch64-* ]]; then
    # aws-lc-sys (pulled in via rustls/hyper-rustls) requires the NEON and
    # crypto extensions to be statically enabled on aarch64 (every real
    # aarch64 CPU has them, but neither clang's bare arm64-apple-macosx
    # target nor the aarch64-linux-gnu assembler enable them by default,
    # so aws-lc-sys's hand-written crypto assembly fails to assemble:
    # "selected processor does not support `aese ...'" etc). Same fix as
    # the rcodesign recipe (for Apple) and needed for aarch64-linux-gnu too.
    export CFLAGS="${CFLAGS} -march=armv8-a+crypto"
fi

cd ${WORKSPACE}/srcdir/RustyIceberg.jl/iceberg_rust_ffi/

# Build the library with native compilation
cargo rustc --release --lib --crate-type=cdylib

# Install the library
install -Dvm 755 "target/${rust_target}/release/libiceberg_rust_ffi.${dlext}" "${libdir}/libiceberg_rust_ffi.${dlext}"
"""

# We could potentially support more platforms, if required.
# Except perhaps i686 Windows and Musl systems.
platforms = [
    Platform("aarch64", "macos"),
    Platform("x86_64",  "linux"),
    Platform("x86_64",  "macos"),
    Platform("aarch64", "linux"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libiceberg_rust_ffi", :libiceberg_rust_ffi),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("OpenSSL_jll"; compat="3.0.14")
]

# iceberg-rust's MSRV is 1.94; pin explicitly rather than relying on
# BinaryBuilder's default (the single newest Rust version known across all
# toolchain shards), which isn't necessarily published for every platform yet.
#
# lock_microarchitecture=false: the compiler wrappers otherwise reject the
# -march flag aarch64-apple-darwin needs above (see rcodesign's recipe,
# which hits the same aws-lc-sys requirement).
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    compilers=[:c, :rust], julia_compat="1.10", preferred_gcc_version=v"5", dont_dlopen=true,
    preferred_rust_version=v"1.94", lock_microarchitecture=false,
)
