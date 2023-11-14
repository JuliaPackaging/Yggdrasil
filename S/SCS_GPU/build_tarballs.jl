using Pkg
using BinaryBuilder

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "SCS_GPU"
version = v"3.2.4"

# Collection of sources required to build SCSBuilder
sources = [
    GitSource("https://github.com/cvxgrp/scs.git", "9024b8ccc1bba6ee797440fb22354cadb9c81839")
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

platforms = CUDA.supported_platforms()
filter!(p -> arch(p) == "x86_64", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libscsgpuindir", :libscsgpuindir, dont_dlopen=true)
]

dependencies = [
    Dependency("OpenBLAS32_jll", v"0.3.10")
]

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform)

    build_tarballs(ARGS, name, version, sources, script, [platform], products,
                   [dependencies; cuda_deps], julia_compat="1.6",
                   augment_platform_block=CUDA.augment)
end
