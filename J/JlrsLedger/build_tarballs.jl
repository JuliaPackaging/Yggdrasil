# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "JlrsLedger"
version = v"0.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Taaitaaiger/jlrs_ledger.git",
              "7a6d9a45e9fd69f577587424c1477bff7b8b09db"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/jlrs_ledger
cargo build --release --verbose
install_license LICENSE
install -Dvm 0755 "target/${rust_target}/release/"*jlrs_ledger".${dlext}" "${libdir}/libjlrs_ledger.${dlext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
is_excluded(p) = arch(p) == "riscv64" || arch(p) == "aarch64" && os(p) == "freebsd"
filter!(!is_excluded, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libjlrs_ledger", :libjlrs_ledger; dlopen_flags=[:RTLD_GLOBAL]),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", compilers=[:c, :rust])
