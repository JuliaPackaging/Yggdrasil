# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Ninja"
version = v"1.10.3" # <-- This is a lie, we're bumping from 1.10.2 to 1.10.3 to create a Julia v1.6+ release with experimental platforms

# Collection of sources required to build ninja
sources = [
    ArchiveSource("https://github.com/ninja-build/ninja/archive/v1.10.2.tar.gz",
    "ce35865411f0490368a8fc383f29071de6690cbadc27704734978221f25e2bed")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd ninja-*/
shorttarget=$(echo $target | grep -o 'linux\|darwin\|mingw\|freebsd')
./configure.py --host=linux --platform=$shorttarget
ninja -j${nproc}
mkdir -p ${bindir}
install ninja${exeext} ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    ExecutableProduct("ninja", :ninja)
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
