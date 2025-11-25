# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "bitshuffle"
version = v"0.5.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/kiyo-masui/bitshuffle.git", "52aec3b80d05606c090956aecfe868489d96b95c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd "${WORKSPACE}/srcdir/bitshuffle"

# Configure
CFLAGS="-std=c99 -fPIC -O3 -DZSTD_SUPPORT"
LDFLAGS=
LIBS="-llz4 -lzstd"

# Build
cd src
${CC} ${CFLAGS} ${LDFLAGS} --shared -o libbitshuffle.${dlext} bitshuffle.c bitshuffle_core.c iochain.c ${LIBS}
cd ..

# Install
install -Dvm 644 src/bitshuffle.h "${includedir}/bitshuffle.h"
install -Dvm 644 src/bitshuffle_core.h "${includedir}/bitshuffle_core.h"
install -Dvm 755 src/libbitshuffle.${dlext} "${libdir}/libbitshuffle.${dlext}"
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
