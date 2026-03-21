using BinaryBuilder, Pkg

name = "Montre"
version = v"0.3.0"

sources = [
	GitSource(
		"https://github.com/myersm0/montre.git",
		"e6c4490757f4b283ff8406031ebc18cecafa7333",
	),
]

script = raw"""
cd $WORKSPACE/srcdir/montre*/
cargo build --release --target $CARGO_BUILD_TARGET
install -Dvm 755 \
	target/$CARGO_BUILD_TARGET/release/*montre_ffi.${dlext} \
	${libdir}/libmontre_ffi.${dlext}
"""


excluded = [
	# Rust 1.94.0 toolchain not available for this platform target
	# (confirmed still failing as of 2026-03-21, after Rust 1.94 was added to Yggdrasil)
	"riscv64-linux-gnu",
	"aarch64-unknown-freebsd",
	# _Unwind linker errors:
	"i686-w64-mingw32",
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
