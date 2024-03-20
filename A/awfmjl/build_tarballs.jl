# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "awfmjl"
version = v"0.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/TravisWheelerLab/AvxWindowFmIndex.git", "2404805a7ddb468b7b10d5f49acd1c2621258dc0")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd AvxWindowFmIndex/
vim CMakeLists.txt 
cmake .
ls
vim CMakeLists.txt 
cmake .
ls lib/
ls lib/FastaVector/
git submodule update --init --recursive --remote
ls lib/FastaVector/
cmake .
make 
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "freebsd"; ),
    Platform("i686", "windows"; ),
    Platform("x86_64", "windows"; )
]


# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
