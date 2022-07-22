# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "web3go"
version = v"0.2.89"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/gochain/web3/archive/refs/tags/v$(version).tar.gz", "4797b4bce370526da0fb04ca2350c36ac5d9894b1cb92a24524d2826ab0c34d6")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/web3-*/
install_license LICENSE
CGO_ENABLED=1 make
install -Dvm 755 "web3${exeext}" "${bindir}/web3${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "freebsd"; ),
    Platform("i686", "windows"; )
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("web3", :web3)
]

# Dependencies that must be installed before this package can be built
dependencies = [Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers = [:go, :c])
