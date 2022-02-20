# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "pigpiod_if2"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/smith-isaac/pigpio.git", "8592e32edaa7d7567b89e648cbf2d53ac6c5ef41")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd pigpio.git/
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("i686", "linux"; libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libpigpiod_if2", :libpigpiod_if2)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
