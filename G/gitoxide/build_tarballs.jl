# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gitoxide"
version = v"0.20.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Byron/gitoxide",
              "08ec3a93d77a1018439a5c41c23729ffed27c5a5"),
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
# PowerPC and 32-bit ARM not supported by sha1-asm
filter!(p -> arch(p) ∉ ("powerpc64le", "armv6l", "armv7l"), platforms)
# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("ein", :ein),
    ExecutableProduct("gix", :gix),
]

llvm_version = v"13.0.1"

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenSSL_jll"; compat="1.1.13"),
    # We need libclang_rt.osx.a for linking the program.
    BuildDependency(PackageSpec(name="LLVMCompilerRT_jll", uuid="4e17d02c-6bf5-513e-be62-445f41c75a11", version=llvm_version); platforms=filter(Sys.isapple, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5",
               preferred_llvm_version=llvm_version,
               compilers=[:c, :rust], lock_microarchitecture=false)
