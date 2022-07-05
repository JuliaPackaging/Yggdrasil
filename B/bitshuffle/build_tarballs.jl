# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "bitshuffle"
version = v"0.4.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/kiyo-masui/bitshuffle.git", "a60471d37a8cbbd8265dc8cfa83a9320abdcb590"),
    GitSource("https://github.com/facebook/zstd.git", "e47e674cd09583ff0503f0f6defd6d23d8b718d3")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/bitshuffle
mkdir -p "${libdir}"
zstd_srcs="../zstd/lib/common/*.c ../zstd/lib/compress/*.c ../zstd/lib/decompress/*.c ../zstd/lib/decompress/*.S"
cc -O3 -std=c99 -Ilz4 -Isrc -I../zstd/lib -fPIC --shared -o "${libdir}/libbitshuffle.${dlext}" src/bitshuffle.c src/iochain.c src/bitshuffle_core.c lz4/lz4.c ${zstd_srcs}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libbitshuffle", :libbitshuffle)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
