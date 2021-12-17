# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oxigraph"
version = v"0.2.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/oxigraph/oxigraph.git", "a21dcbb4f7355d7a00a86fbc5ad2c350a53629c4"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/oxigraph

# Fix linker for BSD platforms
c# sed -i "s/${rust_target}-gcc/${target}-gcc/" "${CARGO_HOME}/config"


atomic_patch -p1 $WORKSPACE/srcdir/patches/memchr_patch.patch

cd lib

# Fix cross-compiling error
mkdir $WORKSPACE/srcdir/oxigraph/lib/.cargo/
cp ${WORKSPACE}/srcdir/config.toml $WORKSPACE/srcdir/oxigraph/lib/.cargo/

cargo build --release -j${nproc}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], preferred_gcc_version=v"7", lock_microarchitecture=false, julia_compat="1.6")
