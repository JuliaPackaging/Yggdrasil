# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Lz4"
version = v"1.10.0"

# Collection of sources required to build Lz4
sources = [
    GitSource("https://github.com/lz4/lz4.git", "ebb370ca83af193212df4dcbadcc5d87bc0de2f0")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lz4
# See <https://github.com/lz4/lz4/issues/1474>
if [[ "${target}" == *86*linux-gnu ]]; then
    ldlibs=-lrt
else
    ldlibs=
fi
make -j${nproc} CFLAGS="-O3 -fPIC" LDLIBS="${ldlibs}"
make install
if [[ "${target}" == *-mingw* ]]; then
    mkdir -p "${prefix}/lib"
    mv "${libdir}/liblz4.a" "${prefix}/lib/."
    mv "${libdir}/liblz4.dll.a" "${prefix}/lib/."
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["liblz4", "msys-lz4"], :liblz4),
    ExecutableProduct("lz4", :lz4),
    ExecutableProduct("lz4c", :lz4c),
    ExecutableProduct("lz4cat", :lz4cat),
    ExecutableProduct("unlz4", :unlz4),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

# Build Trigger: 2
