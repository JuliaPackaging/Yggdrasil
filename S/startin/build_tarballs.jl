# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "startin"
version = v"0.5.2"

sources = [
    GitSource(
        "https://github.com/hugoledoux/startin.git",
        "88ad5557cbd954ec8996f99d9afb74fd1ec174ec"
    )
]

script = raw"""
cd $WORKSPACE/srcdir/startin/
if [[ "${target}" == *-w64-mingw32* ]]; then
    # Fix from https://github.com/rust-lang/rust/issues/32859#issuecomment-573423629, see https://github.com/rust-lang/rust/issues/47048
    cp -f /opt/${target}/${target}/sys-root/lib/{,dll}crt2.o `rustc --print sysroot`/lib/rustlib/${rust_target}/lib
fi
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

products = [
    LibraryProduct("libstartin", :libstartin),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.6")
