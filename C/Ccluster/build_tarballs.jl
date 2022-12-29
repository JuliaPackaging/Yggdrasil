# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Ccluster"
version = v"1.1.8" # <-- This version is a lie, we needed to bump it to update dependencies

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/rimbach/Ccluster/archive/refs/tags/v1.1.7.tar.gz",
                  "725ab22cf7e74afe5a5133ac75ee4a101d7b4ff5f0f25a6b74f5d9bfda8a18d5")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Ccluster*/
if [[ ${target} == *musl* ]]; then
    export CFLAGS="-D_GNU_SOURCE=1 -std=c99 -O2 -funroll-loops -g"
elif [[ ${target} == *mingw* ]]; then
    sed -i -e "s#/lib\>#/$(basename ${libdir})#g" configure; extraflags=--build=MINGW${nbits}
fi
./configure --prefix=$prefix \
    --disable-pthread \
    --disable-static \
    --enable-shared \
    --with-gmp=$prefix \
    --with-mpfr=$prefix \
    --with-flint=$prefix \
    --with-arb=$prefix \
    ${extraflags}
make library -j${nproc}
make install LIBDIR=$(basename ${libdir})
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libccluster", :libccluster)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Arb_jll", compat = "~200.2300.000")
    Dependency("FLINT_jll", compat = "~200.900.000")
    Dependency("GMP_jll", v"6.2.0")
    Dependency("MPFR_jll", v"4.1.1")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

