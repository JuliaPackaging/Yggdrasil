# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "peppi_jlrs"
version = v"0.1.0"
julia_versions = [v"1.10", v"1.11", v"1.12"]

sources = [
    GitSource("https://github.com/jph6366/peppi-jlrs.git",
        "0f0e02ddd062b1ecc00a8409a30be5abce43bb17"),
]

script = raw"""
cd $WORKSPACE/srcdir/peppi-jlrs
cargo build --release
install_license LICENSE
install -Dvm 0755 "target/${rust_target}/release/"*peppi_jlrs.${dlext} "${libdir}/libpeppi_jlrs.${dlext}"
"""

include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)
# Rust toolchain for i686 Windows is unusable
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)
# Rust toolchain 1.91.0 not available for aarch64-freebsd
filter!(p -> !(os(p) == "freebsd" && arch(p) == "aarch64"), platforms)
# zstd-sys has assembly issues on 32-bit platforms
filter!(p -> nbits(p) != 32, platforms)

products = [
    LibraryProduct("libpeppi_jlrs", :libpeppi_jlrs),
]

dependencies = [
    BuildDependency("libjulia_jll"),
    Dependency("Libiconv_jll"; platforms=filter(Sys.isapple, platforms)),
    Dependency("Zstd_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.10", compilers=[:c, :rust])
