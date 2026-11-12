# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "rustfft"
version = v"0.6.0"
julia_versions = [v"1.10", v"1.11", v"1.12", v"1.13"]

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Taaitaaiger/rustfft-jl.git",
              "dc1bbde5580f75af0a2e19aeb58bd5559ee52bce"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/rustfft-jl
cargo build --release --verbose
install_license LICENSE
install -Dvm 0755 "target/${rust_target}/release/"*rustfft_jl".${dlext}" "${libdir}/librustfft.${dlext}"
"""

include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)

# 32-bit Windows is not supported
is_excluded(p) = Sys.iswindows(p) && nbits(p) == 32
filter!(!is_excluded, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("librustfft", :librustfft),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("libjulia_jll"),
    Dependency("Libiconv_jll"; platforms=filter(Sys.isapple, platforms)),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"10", julia_compat="1.10", compilers=[:c, :rust])
