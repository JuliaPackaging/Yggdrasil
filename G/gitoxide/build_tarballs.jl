# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gitoxide"
# Note: upstream doesn't seem to tag new versions of `gitoxide` recently, but
# the version number comes from `Cargo.toml`.
version = v"0.44.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/GitoxideLabs/gitoxide",
              "f0ed2cc0046f866e67944bff9aef0579c12d5852"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gitoxide*/
if [[ "${target}" == *-apple-* ]]; then
    # Help the linker find `libclang_rt.osx.a`
    export RUSTFLAGS="-Clink-args=-L${libdir}/darwin"
fi
cargo build --release
install -Dvm 755 "target/${rust_target}/release/ein${exeext}" "${bindir}/ein${exeext}"
install -Dvm 755 "target/${rust_target}/release/gix${exeext}" "${bindir}/gix${exeext}"
install_license LICENSE-*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# riscv64 does not support Rust
filter!(p -> !(arch(p) == "riscv64"), platforms)
# aarch64-unknown-freebsd does not support Rust
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)
# Rust toolchain for i686 Windows is unusable
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)
# OpenSSL is not found on musl architectures
filter!(p -> !(libc(p) == "musl"), platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("ein", :ein),
    ExecutableProduct("gix", :gix),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # We need libclang_rt.osx.a for linking the program.
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=v"12.0.0");
                    platforms=filter(Sys.isapple, platforms)),
    Dependency("OpenSSL_jll"; compat="3.0.16"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5",
               compilers=[:c, :rust], lock_microarchitecture=false)
