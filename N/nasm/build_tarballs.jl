# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "nasm"
version = v"2.15.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.nasm.us/pub/nasm/releasebuilds/2.15/nasm-2.15.tar.xz", "bc340c2604de5a9aa405b194aae3bcdd86c1631a68a5f4d2165e11d358c2c223")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nasm-*
./autogen.sh 
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("ndisasm", :ndisasm),
    ExecutableProduct("nasm", :nasm)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
