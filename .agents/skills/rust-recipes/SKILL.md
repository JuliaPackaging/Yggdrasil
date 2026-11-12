---
name: rust-recipes
description: Rules for Yggdrasil recipes built with Rust. Use when a build_tarballs.jl passes :rust in compilers, or its script runs cargo or rustc.
---

# Rust packages

```julia
script = raw"""
cd ${WORKSPACE}/srcdir/fd
cargo build --release --locked
install -Dvm 755 "target/${rust_target}/release/fd${exeext}" -t "${bindir}"
install_license LICENSE-APACHE LICENSE-MIT
"""

platforms = supported_platforms()

build_tarballs(...; compilers=[:c, :rust])
```

- **Platforms**: the Rust 1.97 toolchain builds for every platform in `supported_platforms()`, including riscv64, FreeBSD aarch64 and i686 Windows. Many older recipes exclude these as unsupported or "unusable"; don't copy those exclusions. Exclude a platform only for a failure seen in the build log, and say what fails.
- **Lock file**: when upstream commits `Cargo.lock`, build with `--locked`, so the build uses the dependency versions upstream tested instead of resolving new ones.
- **Output**: BinaryBuilder sets `CARGO_BUILD_TARGET`, so Cargo writes to `target/${rust_target}/release`.
- **Build tools**: a binary that must run during the build is built for the host: `env -u CARGO_BUILD_TARGET -u rust_target ${MACHTYPE}-cargo build …` (see `Q/Qiskit`).

## Shared libraries

- **Crate type**: when the crate does not declare `crate-type = ["cdylib"]`, build one with `cargo rustc --release --lib --crate-type=cdylib`.
- **musl**: Rust's musl targets link the C runtime statically, which rules out a cdylib (`cannot produce cdylib … as the target … does not support these crate types`). Link it dynamically there:

    ```bash
    if [[ "${target}" == *-musl* ]]; then
        export RUSTFLAGS="-C target-feature=-crt-static"
    fi
    ```

- **Windows name**: Rust names the DLL `foo.dll`, without the `lib` prefix it uses elsewhere. Install the file under its own name and list both spellings: `LibraryProduct(["libfoo", "foo"], :libfoo)`.
