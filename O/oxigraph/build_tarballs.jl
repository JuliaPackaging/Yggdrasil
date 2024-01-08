# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oxigraph"
version = v"0.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/oxigraph/oxigraph.git", "cffc536eb9df85f4ff474923f4498b25df07c3be")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/oxigraph

git submodule update --init

cd lib

cargo build --release --features rocksdb-pkg-config

install_license LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p -> (arch(p) == "powerpc64le" || Sys.isfreebsd(p) || (Sys.islinux(p) && libc(p) == "musl") || nbits(p) != 64))
platforms = expand_cxxstring_abis(platforms)

# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("oxigraph", :oxigraph),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("RocksDB_jll"),
    RuntimeDependency("Clang_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
compilers=[:c, :rust], julia_compat="1.6", preferred_gcc_version = v"8")
    
