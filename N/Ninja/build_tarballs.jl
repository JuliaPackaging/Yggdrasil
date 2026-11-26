# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Ninja"
version = v"1.13.2"

# Collection of sources required to build ninja
sources = [
    GitSource("https://github.com/ninja-build/ninja", "3441b633c2fe2c494e958780ba0f4227b1327634"; tag="v$(version)"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ninja
shorttarget=$(echo $target | grep -o 'linux\|darwin\|mingw\|freebsd')
env CXXFLAGS=-std=c++14 ./configure.py --host=linux --platform=$shorttarget
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
# Require GCC 5 for C++14
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
