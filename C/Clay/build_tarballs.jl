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
cd $WORKSPACE/srcdir
cd $WORKSPACE/srcdir/clay
echo '#define CLAY_IMPLEMENTATION' > clay.c
echo '#include "./clay.h"' >> clay.c
cd $prefix
clang -shared $WORKSPACE/srcdir/clay/clay.c -fPIC -o clay.so
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("aarch64", "freebsd"; ),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("i686", "windows"; ),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("aarch64", "macos"; ),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("riscv64", "linux"; libc = "glibc"),
    Platform("x86_64", "macos"; ),
    Platform("x86_64", "freebsd"; ),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("x86_64", "windows"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("clay", :claylib)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
