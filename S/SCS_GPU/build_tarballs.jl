using Pkg
using BinaryBuilder

name = "SCS_GPU"
version = v"2.1.3"

# Collection of sources required to build SCSBuilder
sources = [
    GitSource("https://github.com/cvxgrp/scs.git", "07ca69c296312c260027c755f545f05bf45156eb")
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
    Platform("x86_64", "linux"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libscsgpuindir", :libscsgpuindir, dont_dlopen=true)
]

# Dependencies that must be installed before this package can be built

# since https://github.com/cvxgrp/scs/pull/155 scs uses the generic
# cusparse API which was itroduced in CUDA-10.1
cuda_version = v"10.1.243"

dependencies = [
    Dependency("OpenBLAS_jll"),
    BuildDependency(PackageSpec(name="CUDA_full_jll", version=cuda_version))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
