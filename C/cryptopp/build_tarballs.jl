# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "cryptopp"
version = v"8.2"

# Collection of sources required to build CFITSIO
sources = [
    GitSource("https://github.com/weidai11/cryptopp.git", "9dcc26c58213abb8351fbb1b2a7a1d2c667366e4"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cryptopp
make -j${nproc} dynamic
make -j${nproc} install PREFIX=${prefix}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# ARM hits internal compiler errors
#platforms = filter(p -> arch(p) != "armv7l", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcryptopp", :libcryptopp)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6", lock_microarchitecture=false)
