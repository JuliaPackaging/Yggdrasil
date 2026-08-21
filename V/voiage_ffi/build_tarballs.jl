using BinaryBuilder
using Pkg

name = "voiage_ffi"
version = v"2.1.0"

sources = [
    GitSource(
        "https://github.com/edithatogo/voiage.git",
        "964a0fc334ece9509387cd07d43776adf38be240",
    ),
]

script = raw"""
cd ${WORKSPACE}/srcdir/voiage/rust

# Rust's musl targets default to a static C runtime, which cannot produce the
# shared-library product consumed by a JLL package.
if [[ "${target}" == *-musl* ]]; then
    export RUSTFLAGS="-C target-feature=-crt-static"
fi

cargo build \
    --release \
    --locked \
    --package voiage-ffi \
    --target "${rust_target}"

if [[ "${rust_target}" == *-windows-* ]]; then
    source_library="target/${rust_target}/release/voiage_ffi.dll"
else
    source_library="target/${rust_target}/release/libvoiage_ffi.${dlext}"
fi

install -Dvm 755 \
    "${source_library}" \
    "${libdir}/libvoiage_ffi.${dlext}"
install_license ../LICENSE
"""

platforms = supported_platforms()
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms) # Rust toolchain is not available on aarch64-unknown-freebsd
filter!(p -> arch(p) != "riscv64", platforms) # Rust toolchain is not available on riscv64
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms) # Rust toolchain cannot link i686-w64-mingw32 unwinding symbols

products = [
    LibraryProduct("libvoiage_ffi", :libvoiage_ffi),
]

dependencies = Dependency[]

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    julia_compat = "1.10",
    preferred_gcc_version = v"10",
    compilers = [:c, :rust],
)
