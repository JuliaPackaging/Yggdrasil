# Build script for Yggdrasil / BinaryBuilder.jl
# 
# To test locally:
#   julia --project=@. build_tarballs.jl --verbose
#
# To submit to Yggdrasil:
#   1. Fork https://github.com/JuliaPackaging/Yggdrasil
#   2. Create F/fastlowess/build_tarballs.jl with this content
#   3. Open a PR

using BinaryBuilder, Pkg

name = "fastlowess"
version = v"0.99.8"

# Source: the lowess-project repository
# Update the commit hash when releasing a new version
sources = [
    GitSource("https://github.com/thisisamirv/lowess-project.git",
        "4749eba3aebbf9e7d5e2f60ade927a2bfd650f62"),
]

# Build script - compiles the Rust library
script = raw"""
cd $WORKSPACE/srcdir/lowess-project/bindings/julia

# Use the system linker. On Linux, force BFD to avoid "lld not built with zlib support" errors.
if [[ "${target}" == *-linux-* ]]; then
    export RUSTFLAGS="-C linker=${CC} -C link-arg=-fuse-ld=bfd"
else
    export RUSTFLAGS="-C linker=${CC}"
fi

# Build the release library
cargo build --release --target ${rust_target} --target-dir target

# Install the shared library
install -Dvm755 target/${rust_target}/release/*fastlowess_jl.${dlext} -t "${libdir}"
"""

# Target platforms - all supported by BinaryBuilder
platforms = supported_platforms()

# Filter out platforms not supported by Rust
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)
filter!(p -> libc(p) != "musl", platforms)
filter!(p -> !Sys.isfreebsd(p), platforms)
filter!(p -> arch(p) != "riscv64", platforms)

# The library we're building
products = [
    LibraryProduct(["libfastlowess_jl", "fastlowess_jl"], :libfastlowess_jl; dont_dlopen=true),
]

# No JLL dependencies required (self-contained Rust library)
dependencies = Dependency[]

# Build with Rust compiler support
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6",
    compilers=[:rust, :c],
    preferred_gcc_version=v"10",
    lock_microarchitecture=false)
