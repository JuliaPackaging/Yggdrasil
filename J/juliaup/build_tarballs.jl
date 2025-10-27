# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "juliaup"
version = v"1.18.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JuliaLang/juliaup.git", "014eb5826fe8321653a99221b6acac312b9079a8")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/juliaup
cargo build --release
install -Dm 755 "target/${rust_target}/release/juliaup${exeext}" "${bindir}/juliaup${exeext}"
install -Dm 755 "target/${rust_target}/release/julia${exeext}" "${bindir}/julia${exeext}"
"""

include("../../L/libjulia/common.jl")
platforms = julia_supported_platforms(v"1.11.1")

# We don't have rust for these platforms
filter!(p -> !(arch(p) == "aarch64" && Sys.isfreebsd(p)), platforms)
filter!(p -> !(arch(p) == "riscv64"), platforms)

# Rust cross compile is broken for this platform (https://github.com/rust-lang/rust/issues/79609)
filter!(p-> p != Platform("i686", "windows"), platforms)

# Juliaup doesn't currently have these platforms
filter!(p -> !(arch(p) == "powerpc64le"), platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("juliaup", :juliaup) 
    ExecutableProduct("julia", :julia)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("Libiconv_jll"),
    # Links to libgcc_s on linux for something
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(p -> Sys.islinux(p),  platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
	       compilers=[:rust, :c], julia_compat="1.6", preferred_rust_version=v"1.87",
	       lock_microarchitecture=false) # cargo inserts -march
