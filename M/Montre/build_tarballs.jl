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
        "riscv64-linux-gnu",          # Rust 1.94 toolchain not available
        "aarch64-unknown-freebsd",    # Rust 1.94 toolchain not available
        "i686-w64-mingw32",           # _Unwind linker errors
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
