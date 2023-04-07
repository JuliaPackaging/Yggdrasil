# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "JlrsLedger"
version = v"0.0.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Taaitaaiger/jlrs_ledger.git",
              "5ff67d8b0f6b6eea50904290e9888e8779e7cd8f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/jlrs_ledger

if [[ "${target}" == *-musl* ]]; then
    rust_flags="-C target-feature=-crt-static"
fi

RUSTFLAGS=$rust_flags cargo build --release --verbose
install_license LICENSE
install -Dvm 0755 "target/${rust_target}/release/"*jlrs_ledger".${dlext}" "${libdir}/libjlrs_ledger.${dlext}"
"""

# Rust toolchain for i686 Windows is unusable
is_excluded(p) = Sys.iswindows(p) && nbits(p) != 64
platforms = supported_platforms(; exclude=is_excluded)

# The products that we will ensure are always built
products = [
    LibraryProduct("libjlrs_ledger", :libjlrs_ledger; dlopen_flags=[:RTLD_GLOBAL]),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Libiconv_jll"; platforms=filter(Sys.isapple, platforms)),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c, :rust])
