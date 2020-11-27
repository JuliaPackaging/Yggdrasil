# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Singular"
version = v"4.1.4"  # this is actually a snapshot made after 4.1.3p5

# Collection of sources required to build normaliz
sources = [
    GitSource("https://github.com/Singular/Singular.git", "acbd65cb88b23a4271a7494672f740318bcc2bc6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd Singular
./autogen.sh
export CPPFLAGS="-I${prefix}/include"
./configure --prefix=$prefix --host=$target --build=${MACHTYPE} \
    --with-libparse \
    --enable-shared \
    --disable-static \
    --enable-p-procs-static \
    --disable-p-procs-dynamic \
    --enable-gfanlib \
    --with-readline=no \
    --with-gmp=$prefix \
    --with-flint=$prefix \
    --without-python

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = filter!(p -> !Sys.iswindows(p), platforms)
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
    LibraryProduct("libomalloc", :libomalloc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("cddlib_jll"),
    Dependency("FLINT_jll"),
    Dependency("GMP_jll", v"6.1.2"),
    Dependency("MPFR_jll", v"4.0.2"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
