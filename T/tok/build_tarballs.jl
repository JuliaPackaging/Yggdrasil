# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tok"
version = v"1.0.4"

# tok: a plain-text notation for BPMN process models and DMN decisions. tok_jll ships the
# C library of the tok engine (crate tok-capi), which the Julia package TokLang.jl loads.
sources = [
    GitSource("https://github.com/tok-lang-bpm/tok.git",
              "154ad9d2bdeacd6401407ac3291b247c8b801b22"; tag="v$(version)"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/tok/rust
# Build with the Rust toolchain of BinaryBuilder: rust-toolchain.toml would ask rustup for
# the toolchain the engine is developed with, and the workspace declares that version as its
# rust-version, while the engine compiles with Rust 1.88 or newer.
rm -f rust-toolchain.toml
if [[ "${target}" == *-musl* ]]; then
    # a shared library needs the C runtime linked dynamically on musl
    export RUSTFLAGS="-C target-feature=-crt-static"
fi
cargo build --release --locked --ignore-rust-version -p tok-capi
if [[ "${target}" == *-mingw* ]]; then
    lib=tokengine.${dlext}
else
    lib=libtokengine.${dlext}
fi
install -Dvm 755 "target/${rust_target}/release/${lib}" "${libdir}/${lib}"
install -Dvm 644 tok-capi/include/tok.h "${includedir}/tok.h"
install_license ../LICENSE
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
]

products = [
    LibraryProduct(["libtokengine", "tokengine"], :libtokengine),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", compilers=[:c, :rust], preferred_rust_version=v"1.94")
