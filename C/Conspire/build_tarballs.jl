using BinaryBuilder, Pkg

name = "Conspire"
version = v"0.1.0"
sources = [
    GitSource(
        "https://github.com/mrbuche/Conspire.jl.git",
        "5f178e0dce4af644b44bcd4c2599e24efc2de35f",
    ),
]
script = raw"""
cd $WORKSPACE/srcdir/Conspire.jl/deps/conspire_wrapper/
cargo build --release
install -Dvm 755 "target/${rust_target}/release/"*conspire_wrapper.${dlext} "${libdir}/conspire_wrapper.${dlext}"
"""
platforms = supported_platforms()
filter!(p -> arch(p) != "riscv64", platforms)
filter!(p -> libc(p) != "musl", platforms)
filter!(p -> !(arch(p) == "aarch64" && libc(p) == "freebsd"), platforms)
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)
products = [
    LibraryProduct("conspire_wrapper", :libconspire_wrapper)
]
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
    julia_compat="1.6",
    compilers = [:rust, :c]
)
