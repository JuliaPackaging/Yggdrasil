# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FLINT"
version = v"2.6.0"

# Collection of sources required to build FLINT
sources = [
    GitSource("https://github.com/wbhart/flint2.git","1d0a2da90620cb8fa1adc79bc5e39e494381afc7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd flint2/

if [[ ${target} == *musl* ]]; then
   # because of some ordering issue with pthread.h and sched.h includes
   export CFLAGS=-D_GNU_SOURCE=1
elif [[ ${target} == *mingw* ]]; then
   extraflags=--reentrant
fi

./configure --prefix=$prefix --disable-static --enable-shared --with-gmp=$prefix --with-mpfr=$prefix ${extraflags}
make -j${nproc}
make install LIBDIR=$(basename ${libdir})
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libflint", :libflint)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"))
    Dependency(PackageSpec(name="MPFR_jll", uuid="3a97d323-0669-5f0c-9066-3539efd106a3"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
