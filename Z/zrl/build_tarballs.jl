# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "zrl"
version_actual = v"1.1.1"
version = v"1.1.2" # Fake version number for Julia 1.6 compat bound

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/StefanKarpinski/zrl.git", "2ae37960f4c96b61ebb6f217bde1a3ddbe48f8d1"),
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
