# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PYTHIA"
version = v"8.244.0"

# Collection of sources required to complete build
sources = [
    "http://home.thep.lu.se/~torbjorn/pythia8/pythia8244.tgz" =>
    "e34880f999daf19cdd893a187123927ba77d1bf851e30f6ea9ec89591f4c92ca",
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
