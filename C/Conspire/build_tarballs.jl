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
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)
filter!(p -> libc(p) != "musl", platforms)

products = [LibraryProduct("libconspire_wrapper", :libconspire_wrapper)]
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
    julia_compat = "1.11",
)
