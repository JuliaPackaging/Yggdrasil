# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "MPFR"
version = v"4.1.0"

# Collection of sources required to build MPFR
sources = [
    ArchiveSource("https://www.mpfr.org/mpfr-$(version)/mpfr-$(version).tar.xz",
                  "0c98a3f1732ff6ca4ea690552079da9c597872d30e96ec28414ee23c95558a7f"),
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

# We enable experimental platforms as this is a core Julia dependency
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmpfr", :libmpfr),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # We explicitly ask for GMP v6.1.2 so that it is compatible with both GMP v6.1.2 and v6.2.0+
    Dependency("GMP_jll", v"6.1.2"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"5")
