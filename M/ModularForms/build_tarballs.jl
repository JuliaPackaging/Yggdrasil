using BinaryBuilder, Pkg

name = "ModularForms"
version = v"0.2.1"

sources = [GitSource("https://gitlab.com/mraum/ModularForms_jll_src.git",
                     "e7596c82d1a6f4a95325f387c0cd054473a9734e")]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ModularForms_jll_src
if [[ ${target} == *musl* ]]; then
   export CFLAGS=-D_GNU_SOURCE
fi
./configure --prefix=$prefix           \
    --disable-static --enable-shared   \
    --with-gmp=$prefix                 \
    --with-mpfr=$prefix                \
    --with-flint=$prefix               \
    ${extraflags}
make -j${nproc}
make install LIBDIR=$(basename ${libdir})
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmodularforms_jll", :libmodularforms_jll)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="FLINT_jll"), compat = "~301.300")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="^1.6", preferred_gcc_version=v"9")
