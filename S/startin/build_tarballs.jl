# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "startin"
version = v"0.5.3"

sources = [
    GitSource(
        "https://github.com/hugoledoux/startin.git",
        "6ae106bd107f0b33a36cf1270351527fa29deb40"
    )
]

script = raw"""
cd $WORKSPACE/srcdir/startin/
cargo build --features c_api --release -j${nproc}
mkdir ${libdir}
if [[ "${target}" == *-w64-mingw32* ]]; then
    # Windows generates .dlls without the lib prefix
    cp target/${rust_target}/release/startin.dll ${libdir}/libstartin.dll
else
    cp target/${rust_target}/release/libstartin.${dlext} ${libdir}/libstartin.${dlext}
fi
"""

# musl platforms are failing, as is win32
platforms = supported_platforms(; experimental=true)
# `cdylib` apparently doesn't support musl
filter!(p -> libc(p) != "musl", platforms)
# Our Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

products = [
    LibraryProduct("libstartin", :libstartin),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.6")
