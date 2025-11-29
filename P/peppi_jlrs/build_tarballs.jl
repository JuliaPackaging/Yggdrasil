# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

name = "peppi_jlrs"
version = v"0.1.0"
julia_versions = [v"1.10", v"1.11", v"1.12"]

sources = [
    GitSource("https://github.com/jph6366/peppi-jlrs.git",
              "20c8b4b50729b90a395d8e798a2c5827b1da6b82"),
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
