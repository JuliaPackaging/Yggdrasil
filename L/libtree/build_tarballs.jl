# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libtree"
version = v"3.0.0"

sources = [
    ArchiveSource("https://github.com/haampie/libtree/archive/refs/tags/v3.0.0-rc5.tar.gz", "37be3c17a3d646c4e7814c2d642e71060c4193c1426d7725641939614c984a1d")
]

script = raw"""
cd $WORKSPACE/srcdir
cd libtree-*/
make CFLAGS="-Os -Wall -ffunction-sections -fdata-sections" LDFLAGS="-Wl,-s -Wl,--gc-sections -static" "PREFIX=$prefix" install
"""

platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "freebsd"; )
]


products = [
    ExecutableProduct("libtree", :libtree, "bin")
]

dependencies = Dependency[]

# Note: binutils 2.24 has issues with -s and --gc-sections, so use GCC 5 which comes wth a later binutils.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5")

