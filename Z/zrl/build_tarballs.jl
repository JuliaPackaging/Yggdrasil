# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "zrl"
version = v"1.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/StefanKarpinski/zrl.git", "b4d4db4d3ecd866929e3312d29ac4760d0c7d84a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zrl
if [[ "${target}" == *-mingw* ]]; then
    export CPP_DEFINES="-DIO_NOLOCK"
else
    export CPP_DEFINES="-DIO_UNLOCKED"
fi
make
mkdir -p "${bindir}"
cp zrle "${bindir}/zrle${exeext}"
cp zrld "${bindir}/zrld${exeext}"
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("zrle", :zrle),
    ExecutableProduct("zrld", :zrld),
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
