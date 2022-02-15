using BinaryBuilder, Pkg
import Pkg.Types: VersionSpec

name = "ModularForms"
version = v"0.1.0"

sources = [GitSource("https://gitlab.com/mraum/ModularForms_jll_src.git",
                     "4d81d41e625fde3e36dc86df5061313a8447cacd")]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ModularForms_jll_src
if [[ ${target} == *musl* ]]; then
   export CFLAGS=-D_GNU_SOURCE
fi
./configure --prefix=$prefix --disable-static --enable-shared --with-gmp=$prefix --with-mpfr=$prefix --with-flint=$prefix --with-arb=$prefix
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
    Dependency(PackageSpec(name="Arb_jll"), compat = "~200.2200.0"),
    Dependency(PackageSpec(name="FLINT_jll"), compat = "^200.800.401")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="^1.6", preferred_gcc_version=v"9")
