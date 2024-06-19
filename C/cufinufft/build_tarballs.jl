# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase
include(joinpath(@__DIR__, "..", "..", "fancy_toys.jl"))
include(joinpath(@__DIR__, "..", "..", "platforms", "cuda.jl"))

# Build script for the CUDA part of FINUFFT

# Builds for all compatible CUDA platforms, but without microarchitecture expansion (not
# needed for CUDA cuda, and would produce a giant amount of artifacts)
name = "cufinufft"
version = v"2.2.0"

commit_hash = "51892059a4b457a99a2569ac11e9e91cd2e289e7";
preferred_gcc_version=v"13"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/flatironinstitute/finufft.git", commit_hash)
]

# Build script: cufinufft, all possible archs
script = raw"""
cd $WORKSPACE/srcdir/finufft*/

mkdir build && cd build
cmake .. \
    -DCMAKE_PREFIX_PATH="${prefix}" \
    -DCMAKE_INSTALL_PREFIX="${prefix}" \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DFINUFFT_FFTW_SUFFIX="" \
    -DCMAKE_BUILD_TYPE=Release \
    -DFINUFFT_USE_CPU=OFF \
    -DFINUFFT_USE_CUDA=ON \
    -DCMAKE_CUDA_ARCHITECTURES="50;60;70;80;90"
cmake --build . --parallel $nproc --target cufinufft
cmake --install .
"""

# Build for all supported CUDA platforms
platforms = CUDA.supported_platforms(min_version=v"12.5")

# The products that we will ensure are always built
products = [
    LibraryProduct("culibfinufft", :culibfinufft)
]

# Dependencies that must be installed before this package can be built
dependencies = []

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform)

    @show platform
    @show CUDA.is_supported(platform)
    @show cuda_deps
    
    build_tarballs(ARGS, name, version, sources, script, [platform],
                   products, [dependencies; cuda_deps];
                   preferred_gcc_version=preferred_gcc_version,
                   julia_compat="1.9",
                   augment_platform_block=CUDA.augment
                   )
end
