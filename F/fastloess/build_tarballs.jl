# Build script for Yggdrasil / BinaryBuilder.jl

using BinaryBuilder, Pkg

name = "fastloess"
version = v"0.9.0"

# Update the commit hash when releasing a new version
sources = [
	GitSource("https://github.com/thisisamirv/loess-project.git", "8625a3236d39bbb0a2e84cb3d63d9214e6d8eabd"),
]

# Build script
script = raw"""
cd $WORKSPACE/srcdir/loess-project/bindings/julia
# Use the system linker. On Linux, force BFD to avoid "lld not built with zlib support" errors.
export RUSTFLAGS="-C linker=${CC}"
if [[ "${target}" == *-linux-* ]]; then
	RUSTFLAGS="${RUSTFLAGS} -C link-arg=-fuse-ld=bfd"
fi
# Build the release library
cargo build --release --target ${rust_target} --target-dir target
# Install the shared library
install -Dvm755 target/${rust_target}/release/*fastloess_jl.${dlext} -t "${libdir}"
# Install licenses
install_license LICENSE-MIT
install_license LICENSE-APACHE
"""

# Target platforms
platforms = supported_platforms()

# Filter out platforms not supported by Rust
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)
filter!(p -> libc(p) != "musl", platforms)
filter!(p -> !Sys.isfreebsd(p), platforms)
filter!(p -> arch(p) != "riscv64", platforms)

# Products
products = [
	LibraryProduct(["libfastloess_jl", "fastloess_jl"], :libfastloess_jl; dont_dlopen = true),
]

# No JLL dependencies required
dependencies = Dependency[]

# Build with Rust compiler support
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
	julia_compat = "1.6",
	compilers = [:rust, :c],
	preferred_gcc_version = v"10",
	lock_microarchitecture = false)
