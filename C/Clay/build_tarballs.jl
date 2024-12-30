# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Clay"
version = v"0.1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/nicbarker/clay.git", "6a9b723dcce154347452491559b34da528cd657f")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/clay
echo '#define CLAY_IMPLEMENTATION' > clay.c
echo '#include "./clay.h"' >> clay.c
PLATFORM_NAME=$(uname -s)
if [ "$PLATFORM_NAME" = "Darwin" ]; then
    mkdir -p ${prefix}/lib
    clang -shared ${WORKSPACE}/srcdir/clay/clay.c -fPIC -o ${prefix}/lib/libclay.dylib
elif [ "$PLATFORM_NAME" = "Linux" ] || [ "$PLATFORM_NAME" = "FreeBSD" ]; then
    mkdir -p ${prefix}/lib
    clang -shared ${WORKSPACE}/srcdir/clay/clay.c -fPIC -o ${prefix}/lib/libclay.so
else
    mkdir -p ${prefix}/bin
    clang -shared ${WORKSPACE}/srcdir/clay/clay.c -fPIC -o ${prefix}/bin/libclay.dll
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("aarch64", "linux"),
    Platform("riscv64", "linux"),
    Platform("armv6l", "linux"),
    Platform("armv7l", "linux"),
    Platform("powerpc64le", "linux"),
    # Platform("i686", "linux"),
    # Platform("x86_64", "linux"),
    Platform("i686", "Windows"),
    Platform("x86_64", "Windows"),
    Platform("x86_64", "FreeBSD"),
    Platform("aarch64", "FreeBSD"),
    Platform("aarch64", "macos";),
    Platform("x86_64", "macos";),
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libclay", :libclay)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
