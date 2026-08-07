using BinaryBuilder
using Pkg

name = "voiage_ffi"
version = v"2.0.0"

sources = [
    GitSource(
        "https://github.com/edithatogo/voiage.git",
        "e849e89152c306e79c96d0a8a9815ee5faca0529",
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

platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
]

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
