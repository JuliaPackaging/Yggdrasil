using BinaryBuilder

name = "SCS"
version = v"2.1.2"

# Collection of sources required to build SCSBuilder
sources = [
    GitSource("https://github.com/cvxgrp/scs.git", "4ed6c2abf28399c01a0417ff3456b2639560afa6")
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

mkdir -p ${libdir}
cp out/libscs*.${dlext} ${libdir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libscsindir", :libscsindir),
    LibraryProduct("libscsdir", :libscsdir)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenBLAS_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
