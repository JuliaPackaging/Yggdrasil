using BinaryBuilder, Pkg

name = "Montre"
version = v"0.5.1"

sources = [
	GitSource(
		"https://github.com/myersm0/montre.git",
		"68491729bf705ffcb5c65b8506a6864b667cdd4f",
	),
]

script = raw"""
cd $WORKSPACE/srcdir/montre*/
cargo build --release --target $CARGO_BUILD_TARGET
install -Dvm 755 \
	target/$CARGO_BUILD_TARGET/release/*montre_ffi.${dlext} \
	${libdir}/libmontre_ffi.${dlext}
"""

# Rust 1.94.0 toolchain not available for these platform targets
# (confirmed still failing as of 2026-03-21, after Rust 1.94 was added to Yggdrasil)
excluded = [
	"riscv64-linux-gnu",
	"aarch64-unknown-freebsd",
]

platforms = filter(supported_platforms()) do p
	triplet(p) ∉ excluded && !occursin("musl", triplet(p))
end

products = [
	LibraryProduct("libmontre_ffi", :libmontre),
]

dependencies = Dependency[]

build_tarballs(
	ARGS, name, version, sources, script, platforms, products, dependencies;
	julia_compat = "1.10",
	compilers = [:rust, :c],
)
