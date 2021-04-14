# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "racket"
version = v"8.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/racket/racket.git", "8c173392a1fc5f7a0023b6fc3c31c9b28d9cf474")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd racket/
cd racket/src
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
cd ../..
make -j ${nproc} base
cp -r racket/bin ${prefix}/.
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl")
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("racket", :racket),
    ExecutableProduct("raco", :raco)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
