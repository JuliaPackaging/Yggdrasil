using BinaryBuilder

name = "SCS_GPU"
version = v"2.1.1"

# Collection of sources required to build SCSBuilder
sources = [
    GitSource("https://github.com/cvxgrp/scs.git", "e6ab81db115bb37502de0a9917041a0bc2ded313")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/scs*
flags="DLONG=0 USE_OPENMP=0 BLAS64=1 BLASSUFFIX=_64_"
blasldflags="-L${libdir} -lopenblas64_"

CUDA_PATH=$prefix/cuda make BLASLDFLAGS="${blasldflags}" ${flags} out/libscsgpuindir.${dlext}

mkdir -p ${libdir}
cp out/libscs*.${dlext} ${libdir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

platforms = [
    Linux(:x86_64),
    Windows(:x86_64),
    MacOS(:x86_64),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libscsgpuindir", :libscsgpuindir, dont_dlopen=true)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenBLAS_jll"),
    BuildDependency("CUDA_full_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
