# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Antic"
version = v"0.2.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/wbhart/antic/archive/0.2.2.tar.gz",
                  "9e8d518fc9b27807d5bfd173cc81d779a6a1e07ae37bc59427c5223283e9e4d4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd antic*/
if [[ ${target} == *musl* ]]; then
   export CFLAGS=-D_GNU_SOURCE=1;
elif [[ ${target} == *mingw* ]]; then
   sed -i -e "s#/lib\>#/$(basename ${libdir})#g" configure
   extraflags=--build=MINGW${nbits};
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
    LibraryProduct("libantic", :libantic)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="FLINT_jll", uuid="e134572f-a0d5-539d-bddf-3cad8db41a82"))
    Dependency("GMP_jll", v"6.1.2"),
    Dependency("MPFR_jll", v"4.0.2"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
