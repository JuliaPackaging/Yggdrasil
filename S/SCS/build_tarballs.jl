using BinaryBuilder

name = "SCS"
version = v"2.1.1"

# Collection of sources required to build SCSBuilder
sources = [
    GitSource("https://github.com/cvxgrp/scs.git", "e6ab81db115bb37502de0a9917041a0bc2ded313")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/scs*
flags="DLONG=1 USE_OPENMP=0"
blasldflags="-L${prefix}/lib"
# see https://github.com/JuliaPackaging/Yggdrasil/blob/0bc1abd56fa176e3d2cc2e48e7bf85a26c948c40/OpenBLAS/build_tarballs.jl#L23
if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
    flags="${flags} BLAS64=1 BLASSUFFIX=_64_"
    blasldflags+=" -lopenblas64_"
else
    blasldflags+=" -lopenblas"
fi

make BLASLDFLAGS="${blasldflags}" ${flags} out/libscsdir.${dlext}
make BLASLDFLAGS="${blasldflags}" ${flags} out/libscsindir.${dlext}

# Building CUDA dependent libs
make clean

flags="DLONG=0 USE_OPENMP=0"

CUDA_PATH=$prefix/cuda make BLASLDFLAGS="${blasldflags}" ${flags} out/libscsgpuindir.${dlext}

mkdir -p ${libdir}
cp out/libscs*.${dlext} ${libdir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libscsindir", :libscsindir),
    LibraryProduct("libscsdir", :libscsdir),
    LibraryProduct("libscsgpuindir", :libscsgpuindir, dont_dlopen=true)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenBLAS_jll"),
    BuildDependency("CUDA_full_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
