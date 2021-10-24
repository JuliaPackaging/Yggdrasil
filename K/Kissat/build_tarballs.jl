# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CryptoMiniSat"
version = v"5.8.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/arminbiere/kissat.git", "abfa45fb782fa3b7c6e2eb6b939febe74d7270b7"),
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/kissat
./configure -shared
make
mkdir $libdir
mkdir $bindir
cp build/kissat $bindir
cp build/libkissat.so $libdir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"9")
