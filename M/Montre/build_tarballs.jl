using BinaryBuilder, Pkg

name = "Montre"
version = v"0.2.0"

sources = [
	GitSource(
		"https://github.com/myersm0/montre.git",
		"54a24f413d50a4c18719b8e3018159626799bc11",
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
	"riscv64-linux-gnu",
	"aarch64-unknown-freebsd",
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
