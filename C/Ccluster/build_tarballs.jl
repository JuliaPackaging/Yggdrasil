# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Ccluster"
version = v"1.1.6"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/rimbach/Ccluster/archive/refs/tags/v1.1.6.tar.gz", "85b866a5485403d8af944965c531645709c21ee0810adfe720258e5c509332e1")
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
    Dependency(PackageSpec(name="Arb_jll", uuid="d9960996-1013-53c9-9ba4-74a4155039c3"))
    Dependency(PackageSpec(name="FLINT_jll", uuid="e134572f-a0d5-539d-bddf-3cad8db41a82"))
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"), v"6.1.2"; compat="6.1.2")
    Dependency(PackageSpec(name="MPFR_jll", uuid="3a97d323-0669-5f0c-9066-3539efd106a3"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
