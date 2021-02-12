using BinaryBuilder

name = "Tokei"
version = v"12.1.2"

sources = [
    GitSource("https://github.com/XAMPPRocky/tokei", "7e0b30ff4c1fe78fe2cc615d1f0f52c7ce6cb761")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${prefix}/bin
cd $WORKSPACE/srcdir/tokei*/
cargo build --all-features --release
cp target/${rust_target}/release/tokei${exeext} ${bindir}/
"""

platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    ExecutableProduct("tokei", :tokei),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust])
