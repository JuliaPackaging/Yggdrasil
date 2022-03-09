# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Lz4"
version = v"1.9.3"

# Collection of sources required to build Lz4
sources = [
    ArchiveSource("https://github.com/lz4/lz4/archive/v$(version).tar.gz",
                  "030644df4611007ff7dc962d981f390361e6c97a34e5cbc393ddfbe019ffe2c1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lz4-*/
make -j${nproc} CFLAGS="-O3 -fPIC"
make install
if [[ "${target}" == *-mingw* ]]; then
    mkdir -p "${prefix}/lib"
    mv "${libdir}/liblz4.a" "${prefix}/lib/."
    mv "${libdir}/liblz4.dll.a" "${prefix}/lib/."
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

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
