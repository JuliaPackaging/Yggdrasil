# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ninja"
version = v"1.10.0"

# Collection of sources required to build ninja
sources = [
    ArchiveSource("https://github.com/ninja-build/ninja/archive/v1.10.0.tar.gz",
    "3810318b08489435f8efc19c05525e80a993af5a55baa0dfeae0465a9d45f99f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd ninja-*/
shorttarget=$(echo $target | grep -o 'linux\|darwin\|mingw\|freebsd')
./configure.py --host=linux --platform=$shorttarget
ninja -j${nproc}
mkdir -p ${bindir}
if [[ $target == *mingw* ]]; then
    install ninja.exe ${bindir}
else
    install ninja ${bindir}
fi

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("ninja", :ninja)
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
