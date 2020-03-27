# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FLINT"
version = v"0.0.1"

# Collection of sources required to build FLINT
sources = [
    GitSource("https://github.com/wbhart/flint2.git","dd1021a6cbaca75d94e6e066c26a3a5622884a7c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd flint2/

libsubdir=lib

if [[ ${target} == *musl* ]]; then
   # because of some ordering issue with pthread.h and sched.h includes
   export CFLAGS=-D_GNU_SOURCE=1
   # and properly define _GNU_SOURCE here as well to avoid many warnings
   sed -i -e 's/#define _GNU_SOURCE$/#define _GNU_SOURCE 1/' thread_pool.h configure
elif [[ ${target} == *mingw* ]]; then
   # fix arch detection:
   sed -i -e 's/$(ARCH)/$ARCH/g' configure
   extraflags=--reentrant
   libsubdir=bin
fi

./configure --prefix=$prefix --disable-static --enable-shared --with-gmp=$prefix --with-mpfr=$prefix ${extraflags}
make -j${nproc}
make install LIBDIR=$libsubdir
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
