# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Ninja"
version = v"1.11.0"

# Collection of sources required to build ninja
sources = [
    ArchiveSource("https://github.com/ninja-build/ninja/archive/v$(version).tar.gz",
    "3c6ba2e66400fe3f1ae83deb4b235faf3137ec20bd5b08c29bfc368db143e4c6")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ninja-*
shorttarget=$(echo $target | grep -o 'linux\|darwin\|mingw\|freebsd')
env CXXFLAGS=-std=c++11 ./configure.py --host=linux --platform=$shorttarget
ninja -j${nproc}
mkdir -p ${bindir}
install ninja${exeext} ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("ninja", :ninja)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
