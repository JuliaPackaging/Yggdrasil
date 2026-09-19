# Copyright, the Moreau authors
# SPDX-License-Identifier: Apache-2.0

using BinaryBuilder

name = "Moreau_CPU"
version = v"0.4.1"
sources = [
    GitSource("https://github.com/moreau-project/moreau.git",
        "799c9fdc0d3cb7675e723a3fb9eb413015a64f93"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/moreau
install_license LICENSE NOTICE
cd packages/moreau-cpu
# Rust's musl target otherwise defaults to a static CRT and disallows cdylibs.
if [[ ${target} == *-musl* ]]; then
    export RUSTFLAGS="${RUSTFLAGS} -C target-feature=-crt-static"
fi
cargo build --locked --release --lib --features c-api
mkdir -p ${libdir} ${includedir}
if [[ ${target} == *-mingw* ]]; then
    cp target/${rust_target}/release/moreau.dll ${libdir}/moreau_cpu.dll
else
    cp target/${rust_target}/release/libmoreau.${dlext} ${libdir}/libmoreau_cpu.${dlext}
fi
cp ../moreau-c/include/moreau.h ${includedir}/
"""

# The Julia wrapper and C interface use 64-bit sparse indices.
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
]
products = [LibraryProduct(["libmoreau_cpu", "moreau_cpu"], :libmoreau)]
dependencies = [Dependency("CompilerSupportLibraries_jll")]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.12", compilers=[:c, :rust], preferred_gcc_version=v"10",
    preferred_rust_version=v"1.87.0", lock_microarchitecture=false)
