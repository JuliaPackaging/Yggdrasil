# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cddlib"
# upstream 0.94j mapped to semantic versioning
version = v"0.94.10"

# Collection of sources required to build cddlib
sources = [
    GitSource("https://github.com/cddlib/cddlib","6d980f2258052f6cf47acca611d6a268d657dfc7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/*
sed -i '/^libcddgmp_la_LDFLAGS/ s/$/  $(CDD_LDFLAGS)/' lib-src/Makefile.gmp.am
./bootstrap # needed because we are building a commit and not a release
CPPFLAGS=-I${prefix}/include ./configure --prefix=${prefix} --host=${target}
cd lib-src # Call make in the lib-src subfolder to avoid building the doc folder since pdflatex is not installed
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcdd", :libcdd)
    LibraryProduct("libcddgmp", :libcddgmp)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.1.2"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

