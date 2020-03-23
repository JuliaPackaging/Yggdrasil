# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "zrl"
version = v"1.0.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/StefanKarpinski/zrl/archive/v1.0.1.tar.gz", "b696ca1e4dffe7c87b739cf96e0a2378091cb2631a6509499b6e4cc2d9ed9994"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zrl-1.0.1
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
