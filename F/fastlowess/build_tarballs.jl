# Build script for Yggdrasil / BinaryBuilder.jl

using BinaryBuilder, Pkg

name = "fastlowess"
version = v"5.0.0"

# Update the commit hash when releasing a new version
sources = [
    GitSource("https://github.com/thisisamirv/lowess-project.git", "a9a806b606e397cc7b3d81a984a3056769977dae"),
]

# Build script
script = raw"""
cd $WORKSPACE/srcdir/lowess-project/bindings/julia
# Use the system linker. On Linux, force BFD to avoid "lld not built with zlib support" errors.
export RUSTFLAGS="-C linker=${CC}"
if [[ "${target}" == *-linux-* ]]; then
	RUSTFLAGS="${RUSTFLAGS} -C link-arg=-fuse-ld=bfd"
fi
if [[ "${rust_target}" == *-linux-musl* ]]; then
    # Musl targets default to a fully static CRT, which does not support cdylib.
    RUSTFLAGS="${RUSTFLAGS} -C target-feature=-crt-static"
fi
# Build the release library
cargo build --release --target ${rust_target} --target-dir target
# Install the shared library
install -Dvm755 target/${rust_target}/release/*fastlowess_jl.${dlext} -t "${libdir}"
# Install licenses
install_license LICENSE-MIT
install_license LICENSE-APACHE
"""

# Target platforms
platforms = supported_platforms()

# Filter out platforms not supported by Rust
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)
filter!(p -> !Sys.isfreebsd(p), platforms)
filter!(p -> arch(p) != "riscv64", platforms)

# Products
products = [
    LibraryProduct(["libfastlowess_jl", "fastlowess_jl"], :libfastlowess_jl; dont_dlopen=true),
]

# No JLL dependencies required
dependencies = Dependency[]

# Build with Rust compiler support
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6",
    compilers=[:rust, :c],
    preferred_gcc_version=v"10",
    lock_microarchitecture=false)
