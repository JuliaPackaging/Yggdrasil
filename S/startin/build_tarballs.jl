# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "startin"
version = v"0.4.9"

sources = [
    ArchiveSource(
        "https://github.com/evetion/startin/archive/c-interface.zip",  # PR branch
        "d3a987e9ab20ee3504c8c79f0940ce22527e23ed8b029e8d12136831fe996c63"
    )
]

script = raw"""
cd $WORKSPACE/srcdir/startin-c-interface/
cargo build --features c_api --release -j${nproc}
mkdir ${libdir}
cp target/${rust_target}/release/libstartin.${dlext} ${libdir}
"""

platforms = supported_platforms()

products = [
LibraryProduct("libstartin", :libstartin),
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust])
