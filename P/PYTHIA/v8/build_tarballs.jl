# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PYTHIA"
version = v"8.309.0"

# Collection of sources required to complete build
sources = [
    "https://pythia.org/download/pythia83/pythia8309.tar" =>
    "94ce746ba5154a661758c3cfbb77c253324467304fdc6837142ec44708ef6494",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd pythia8244/
./configure --prefix=${prefix} --enable-shared --enable-64bit
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("x86_64", "macos")
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libpythia8", :libpythia8)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
