using BinaryBuilder, Pkg

name = "Polymers"
version = v"0.3.6"
sources = [
    GitSource(
        "https://github.com/sandialabs/Polymers.git",
        "c977b84d921019b3731b2c6cce2537e1d03ebcef",
    ),
]
script = raw"""
cd $WORKSPACE/srcdir/Polymers
cargo build --release --features extern
install -Dvm 755 "target/${rust_target}/release/"*polymers.${dlext} "${libdir}/libpolymers.${dlext}"
"""

platforms = supported_platforms()
# Rust toolchain is unusable on i686-w64-mingw32
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)
# Also, can't build cdylib for Musl systems
filter!(p -> libc(p) != "musl", platforms)

products = [LibraryProduct("libpolymers", :libpolymers)]
dependencies = Dependency[]
build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    compilers = [:c, :rust],
    preferred_gcc_version = v"7",
    lock_microarchitecture = false,
    julia_compat = "1.6",
)
