# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "peppi_jlrs"
version = v"0.1.0"
julia_versions = [v"1.10", v"1.11", v"1.12"]

sources = [
    GitSource("https://github.com/jph6366/peppi-jlrs.git",
              "65ba889ba10d386bbbd11258aea51b32081ede71"),
]

script = raw"""
cd $WORKSPACE/srcdir/peppi-jlrs
cargo build --release --verbose
install_license LICENSE
install -Dvm 0755 "target/${rust_target}/release/"*peppi_jlrs".${dlext}" "${libdir}/libpeppi_jlrs.${dlext}"
"""

include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)

# Rust toolchain for i686 Windows is unusable
is_excluded(p) = Sys.iswindows(p) && nbits(p) == 32
filter!(!is_excluded, platforms)

products = [
    LibraryProduct("libpeppi_jlrs", :libpeppi_jlrs),
]

dependencies = [
    BuildDependency("libjulia_jll"),
    Dependency("Libiconv_jll"; platforms=filter(Sys.isapple, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"10", julia_compat="1.10", compilers=[:c, :rust])
