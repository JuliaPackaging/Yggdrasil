# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Arb"
version = v"2.18.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/fredrik-johansson/arb.git", "137f3b5e13e31163634e91f8547aaae7c1ad8c32")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd arb/

if [[ ${target} == *musl* ]]; then
   export CFLAGS=-D_GNU_SOURCE=1
elif [[ ${target} == *mingw* ]]; then
   # /lib is hardcoded in many places
   sed -i -e "s#/lib\>#/$(basename ${libdir})#g" configure
   # MSYS_NT-6.3 is not detected as MINGW
   extraflags=--build=MINGW${nbits}
fi

./configure --prefix=$prefix --disable-static --enable-shared --with-gmp=$prefix --with-mpfr=$prefix --with-flint=$prefix ${extraflags}
make -j${nproc}
make install LIBDIR=$(basename ${libdir})
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libarb", :libarb)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="FLINT_jll", uuid="e134572f-a0d5-539d-bddf-3cad8db41a82"))
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"))
    Dependency(PackageSpec(name="MPFR_jll", uuid="3a97d323-0669-5f0c-9066-3539efd106a3"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
