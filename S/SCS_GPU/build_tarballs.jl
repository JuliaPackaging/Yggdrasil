using Pkg
using BinaryBuilder

name = "SCS_GPU"
version = v"3.2.1"

# Collection of sources required to build SCSBuilder
sources = [
    GitSource("https://github.com/cvxgrp/scs.git", "f2da64d314d86a97ebb8e957f215f27f9e2a7b79")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/scs*
flags="DLONG=0 USE_OPENMP=0"
blasldflags="-L${libdir} -lopenblas"

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
    Dependency("OpenBLAS32_jll", v"0.3.10"),
    BuildDependency(PackageSpec(name="CUDA_full_jll", version=cuda_version))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
