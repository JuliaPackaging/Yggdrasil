# This script clones gmp-mpfr-sys (LGPL-3.0+) fresh at build time and patches
# its build.rs (gmp-mpfr-sys-cross-compile-fix.diff) for cross-compile safety.
# build.rs itself carries its own permissive notice:
#
#   Copyright © 2017-2026 Trevor Spiteri
#
#   Copying and distribution of this file, with or without
#   modification, are permitted in any medium without royalty provided
#   the copyright notice and this notice are preserved. This file is
#   offered as-is, without any warranty.
#
# We also install a copy of gmp-mpfr-sys's LGPL license alongside Jerbie's.
using BinaryBuilder, Pkg

name = "Jerbie"
version = v"0.1.0"

sources = [
    GitSource("https://github.com/JuliaSymbolics/Jerbie.jl.git", "30b6c8cd6bb598abfdfebad06eca10dae3b4ae24"),
]

script = raw"""
cd $WORKSPACE/srcdir/Jerbie.jl/Jerbie.jl/deps/egg-jerbie

# gmp-mpfr-sys's use-system-libs system-lib detection normally compiles AND
# executes a test binary to read off preprocessor macros, which fails when
# cross-compiling (can't run a Darwin binary on the Linux BB sandbox). Fetch
# the real, unmodified crate fresh and apply a minimal diff (preprocess-only
# instead of execute) rather than vendoring a modified copy in this repo.
git clone https://gitlab.com/tspiteri/gmp-mpfr-sys.git "$WORKSPACE/gmp-mpfr-sys-fixed"
git -C "$WORKSPACE/gmp-mpfr-sys-fixed" checkout b22a67c56a0dabda1a30c261f98833bd7f2526f8
patch -d "$WORKSPACE/gmp-mpfr-sys-fixed" -p1 < gmp-mpfr-sys-cross-compile-fix.diff

cat >> Cargo.toml <<EOF
[patch.crates-io]
gmp-mpfr-sys = { path = "$WORKSPACE/gmp-mpfr-sys-fixed" }
EOF

# musl needs crt-static disabled for cdylib
if [[ "${target}" == *-musl* ]]; then
    export RUSTFLAGS="-C target-feature=-crt-static"
fi

cargo build --release --features gmp-mpfr-sys/use-system-libs
install -Dvm 755 target/${rust_target}/release/*jerbie.${dlext} "${libdir}/libjerbie.${dlext}"
install_license ../../../LICENSE "$WORKSPACE/gmp-mpfr-sys-fixed/LICENSE-LGPL.md"
"""

platforms = supported_platforms()
# i686 Windows Rust toolchain is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

products = [
    LibraryProduct("libjerbie", :libjerbie)
]

dependencies = Dependency[
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("GMP_jll"),
    Dependency("MPFR_jll"),
    Dependency("MPC_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.9", compilers=[:rust, :c], preferred_gcc_version=v"8")
