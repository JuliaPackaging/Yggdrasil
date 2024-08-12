# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../../"
include(joinpath(@__DIR__, "..", "..", "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "cuLAMMPS"
version = v"1.0.0" # Equivalent to stable_2Aug2023_update3

# Version table
# 1.0.0 -> https://github.com/lammps/lammps/releases/tag/stable_29Oct2020

# https://docs.lammps.org/Manual_version.html
# We have "stable" releases and we have feature/patch releases
# We are going with:
# 2.ODD -> stable
# 2.EVEN -> features

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lammps/lammps.git", "46265e36ce79e4b42c9e5229b72a0ce2485845cd")
]

# Bash recipe for building across all platforms
# LAMMPS DPD packages do not work on all platforms
script = raw"""
cd $WORKSPACE/srcdir/lammps/
mkdir build && cd build/
cmake -C ../cmake/presets/most.cmake -C ../cmake/presets/nolib.cmake ../cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DLAMMPS_EXCEPTIONS=ON \
    -DPKG_MPI=ON \
    -DPKG_EXTRA-FIX=ON \
    -DPKG_ML-SNAP=ON \
    -DPKG_ML-PACE=ON \
    -DPKG_ML-POD=ON \
    -DPKG_DPD-BASIC=ON \
    -DPKG_DPD-MESO=ON \
    -DPKG_DPD-REACT=ON \
    -DPKG_DPD-SMOOTH=ON \
    -DPKG_USER-MESODPD=ON \
    -DPKG_USER-DPD=ON \
    -DPKG_USER-SDPD=ON \
    -DPKG_MANYBODY=ON \
    -DPKG_MOLECULE=ON \
    -DPKG_REPLICA=ON \
    -DPKG_SHOCK=ON \
    -DLEPTON_ENABLE_JIT=no \
    -DGPU_API=cuda

make -j${nproc}
make install

if [[ "${target}" == *mingw* ]]; then
    cp *.dll ${prefix}/bin/
fi
"""

# Build for all supported CUDA > v11
platforms = expand_cxxstring_abis(CUDA.supported_platforms(min_version=v"11.0"))
# Cmake toolchain breaks on aarch64, so only x86_64 for now
filter!(p -> arch(p)=="x86_64", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcufinufft", :libcufinufft)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll")),
]

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    # Static SDK is used in CMake toolchain
    cuda_deps = CUDA.required_dependencies(platform; static_sdk=true)

    build_tarballs(ARGS, name, version, sources, script, [platform],
                   products, [dependencies; cuda_deps];
                   preferred_gcc_version=v"8",
                   julia_compat="1.6",
                   augment_platform_block=CUDA.augment,
                   lazy_artifacts=true
                   )
end
