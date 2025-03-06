# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "bitshuffle"
version = v"0.5.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/kiyo-masui/bitshuffle.git", "b9a1546133959298c56eee686932dbb18ff80f7a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/bitshuffle
mkdir -p "${libdir}"
cc -O3 -std=c99 -DZSTD_SUPPORT -I${includedir} -Isrc -fPIC --shared -o "${libdir}/libbitshuffle.${dlext}" src/bitshuffle.c src/iochain.c src/bitshuffle_core.c -lzstd -llz4
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libbitshuffle", :libbitshuffle)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Lz4_jll"),
    Dependency("Zstd_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
