using BinaryBuilder, Pkg

name = "Flavio"
version = v"0.1.0"
sources = [
    GitSource(
        "https://github.com/mrbuche/Flavio.jl.git",
        "639ff6e5a9660a3dd4f2c046c1f13906cf45ddcb",
    ),
]
script = raw"""
cd $WORKSPACE/srcdir/Flavio.jl/deps/flavioso/
cargo build --release
install -Dvm 755 "target/${rust_target}/release/"*flavioso.${dlext} "${libdir}/libflavioso.${dlext}"
"""

platforms = supported_platforms()
filter!(p -> !(Sys.iswindows(p) && arch(p) == "i686"), platforms)
filter!(p -> libc(p) != "musl", platforms)

products = [LibraryProduct("libflavioso", :libflavioso)]
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
