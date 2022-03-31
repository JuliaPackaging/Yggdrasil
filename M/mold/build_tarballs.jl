# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mold"
version = v"1.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/rui314/mold.git", "c1af9c97e763a1d521889191a83b27bd6c43b351")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd mold/
make -j${nproc}
make install PREFIX="${prefix}" BINDIR="${bindir}" LIBDIR="${libdir}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl")
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("mold", :mold)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="xxHash_jll", uuid="5fdcd639-92d1-5a06-bf6b-28f2061df1a9"))
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"11.1.0")
