# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
include(joinpath(@__DIR__, "..", "..", "fancy_toys.jl"))
include(joinpath(@__DIR__, "..", "..", "platforms", "cuda.jl"))

name = "LAMMPS"
version = v"2.7.0" # Equivalent to stable_29Aug2024

# Version table
# 1.0.0 -> https://github.com/lammps/lammps/releases/tag/stable_29Oct2020
# 2.0.0 -> https://github.com/lammps/lammps/releases/tag/stable_29Sep2021
# 2.2.0 -> https://github.com/lammps/lammps/releases/tag/stable_29Sep2021_update2
# 2.3.0 -> https://github.com/lammps/lammps/releases/tag/stable_23Jun2022_update1
# 2.3.2 -> https://github.com/lammps/lammps/releases/tag/stable_23Jun2022_update3
# 2.4.0 -> https://github.com/lammps/lammps/releases/tag/patch_28Mar2023_update1
# 2.4.1 -- Enables DPD packages
# 2.5.0 -> https://github.com/lammps/lammps/releases/tag/stable_2Aug2023_update3
# 2.5.1 -- Enables MPI
# 2.5.2 -- Disables MPI for Windows
# 2.6.0 -> https://github.com/lammps/lammps/releases/tag/stable_29Aug2024
# 2.7.0 -- Enables CUDA

# https://docs.lammps.org/Manual_version.html
# We have "stable" releases and we have feature/patch releases
# We are going with:
# 2.ODD -> stable
# 2.EVEN -> features

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lammps/lammps.git", "570c9d190fee556c62e5bd0a9c6797c4dffcc271")
]

# Bash recipe for building across all platforms
# LAMMPS DPD packages do not work on all platforms
script = raw"""
# For this specific target during the audit liblammps.so fails to find libgfortran.so
# This is the same hack as used by MPITrampoline:
# <https://github.com/JuliaPackaging/Yggdrasil/pull/5028#issuecomment-1166388492>
if [[ "${target}" == x86_64-linux-gnu-cxx11-mpi+mpitrampoline ]]; then
    INSTALL_RPATH=(-DCMAKE_INSTALL_RPATH='$ORIGIN')
else
    INSTALL_RPATH=()
fi

# The MPI enabled LAMMPS_jll doesn't load properly on windows
if [[ "${target}" == *mingw* ]]; then
    MPI_OPTION="OFF"
else
    MPI_OPTION="ON"
fi

cd $WORKSPACE/srcdir/lammps/
mkdir build && cd build/
cmake -C ../cmake/presets/most.cmake -C ../cmake/presets/nolib.cmake ../cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    "${INSTALL_RPATH[@]}" \
    -DBUILD_SHARED_LIBS=ON \
    -DLAMMPS_EXCEPTIONS=ON \
    -DBUILD_MPI=${MPI_OPTION} \
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
     -DGPU_AAPI=cuda

make -j${nproc}
make install

if [[ "${target}" == *mingw* ]]; then
    cp *.dll ${prefix}/bin/
fi
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# platforms = supported_platforms(; experimental=true)
platforms = CUDA.supported_platforms(min_version=v"11.0")
platforms = expand_cxxstring_abis(platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.3.1", OpenMPI_compat="4.1.6, 5")
# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
# platforms = filter(p -> !(p["mpi"] == "openmpi" && nbits(p) == 32), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

platforms = filter(p -> !(Sys.isfreebsd(p) || libc(p) == "musl"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("liblammps", :liblammps),
    ExecutableProduct("lmp", :lmp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll")),
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    # Static SDK is used in CMake toolchain
    cuda_deps = CUDA.required_dependencies(platform; static_sdk=true)

    build_tarballs(ARGS, name, version, sources, script, [platform],
                   products, [dependencies; cuda_deps];
                   preferred_gcc_version=v"8",
                   julia_compat="1.6",
                   augment_platform_block=CUDA.augment*augment_platform_block,
                   lazy_artifacts=true
                   )
end
