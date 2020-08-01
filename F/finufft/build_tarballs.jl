# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "finufft"
version = v"1.1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/flatironinstitute/finufft.git", "5b92daf4244c92844dd2640ef80457c030e1bf25")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/finufft/
# The buggy makefile forces `-fopenmp` even if `OMP=OFF`
make lib -j${nproc} OMP="OFF" OMPFLAGS="" CFLAGS="-fPIC -O3 -funroll-loops -fcx-limited-range"
cp lib/libfinufft.so "${libdir}/libfinufft.${dlext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libfinufft", :libfinufft)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8")
