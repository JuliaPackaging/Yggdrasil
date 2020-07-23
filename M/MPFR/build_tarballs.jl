# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "MPFR"
version = v"4.1.0"

# Collection of sources required to build MPFR
sources = [
    "https://www.mpfr.org/mpfr-current/mpfr-$(version).tar.xz" =>
    "0c98a3f1732ff6ca4ea690552079da9c597872d30e96ec28414ee23c95558a7f",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mpfr-*
./configure --prefix=$prefix --host=$target --enable-shared --disable-static --with-gmp=${prefix} --enable-thread-safe --enable-shared-cache --disable-float128 --disable-decimal-float
make -j${nproc}
make install

# On Windows, make sure non-versioned filename exists...
if [[ ${target} == *mingw* ]]; then
    cp -v ${prefix}/bin/libmpfr-*.dll ${prefix}/bin/libmpfr.dll
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmpfr", :libmpfr),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "GMP_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
