# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Singular"
version = v"4.1.3"

# Collection of sources required to build normaliz
sources = [
    GitSource("https://github.com/Singular/Sources.git", "4c1fc06f2d81e12a8e75a5419444cb157fbe45e9"),
]

# Bash recipe for building across all platforms
script = raw"""
cd Sources
./autogen.sh
./configure --prefix=$prefix --host=$target --build=${MACHTYPE} \
    --with-libparse \
    --enable-shared \
    --disable-static \
    --enable-p-procs-static \
    --disable-p-procs-dynamic \
    --disable-gfanlib \
    --with-readline=no \
    --with-gmp=$prefix \
    --with-flint=$prefix \
    --without-python

#    --with-ntl=$prefix

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = filter!(p -> !(p isa Windows), platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libpolys", :libpolys),
    LibraryProduct("libSingular", :libsingular),
    # LibraryProduct("customstd", :customstd),
    # LibraryProduct("subsets", :subsets),
    ExecutableProduct("Singular", :Singular),
    ExecutableProduct("libparse", :libparse),
    # LibraryProduct("syzextra", :syzextra),
    # LibraryProduct("interval", :interval),
    LibraryProduct("libfactory", :libfactory),
    LibraryProduct("libsingular_resources", :libsingular_resources),
    LibraryProduct("libomalloc", :libomalloc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("FLINT_jll"),
    Dependency("GMP_jll"),
    Dependency("MPFR_jll"),
    #Dependency("ntl_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
