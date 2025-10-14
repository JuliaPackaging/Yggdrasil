# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

name = "rustfft"
version = v"0.5.1"
julia_versions = [v"1.10", v"1.11", v"1.12"]

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Taaitaaiger/rustfft-jl.git",
              "3cb9dc40222ef10bff671408262079f492f06c99"),
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

# 32-bit Windows and AArch64 FreeBSD are not supported
is_excluded(p) = (Sys.iswindows(p) && nbits(p) == 32) || (Sys.isfreebsd(p) && arch(p) == "aarch64")
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
