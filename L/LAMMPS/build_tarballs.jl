# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg, BinaryBuilderBase
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

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
# 2.6.1 -- BLAS & Openmp
# 2.7.0 -- Enables CUDA

# https://docs.lammps.org/Manual_version.html
# We have "stable" releases and we have feature/patch releases
# We are going with:
# 2.ODD -> stable
# 2.EVEN -> features

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lammps/lammps.git", "570c9d190fee556c62e5bd0a9c6797c4dffcc271"),
]

# Bash recipe for building across all platforms
# LAMMPS DPD packages do not work on all platforms
script = raw"""
# For this specific target during the audit liblammps.so fails to find libgfortran.so
# This is the same hack as used by MPITrampoline:
# <https://github.com/JuliaPackaging/Yggdrasil/pull/5028#issuecomment-1166388492>
if [[ "${bb_full_target}" == *cxx11* && "${bb_full_target}" == *mpi+mpitrampoline* ]]; then
    INSTALL_RPATH=(-DCMAKE_INSTALL_RPATH='$ORIGIN')
else
    INSTALL_RPATH=()
fi

cmake_extra_args=""

# The MPI enabled LAMMPS_jll doesn't load properly on windows
if [[ "${bb_full_target}" == *mingw* ]] || [[ "${bb_full_target}" == *mpi\+none* ]]; then
    MPI_OPTION="OFF"
else
    MPI_OPTION="ON"
fi

if [[ "${bb_full_target}" == *cuda\+none* || "${bb_full_target}" != *cuda* ]]; then
    GPU_OPTION="OFF"
else
    GPU_OPTION="ON"
    export PATH=$PATH:$prefix/cuda/bin/
    export CUDA_PATH=$prefix/cuda/
    ln -s $prefix/cuda/lib/stubs/libcuda.so $prefix/cuda/lib/libcuda.so
    cmake_extra_args="\
        -DCUDA_TOOLKIT_ROOT_DIR=$prefix/cuda/ \
        -DCMAKE_EXE_LINKER_FLAGS=-Wl,--allow-shlib-undefined -Wl,--allow-undefined-file=libcuda.so.1 \
    "
fi

if [[ "${target}" == *-mingw* ]]; then
    LBT=blastrampoline-5
else
    LBT=blastrampoline
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
    -DBUILD_OMP=ON \
    -DUSE_INTERNAL_LINALG=OFF \
    -DBLAS_LIBRARIES="-l${LBT}" \
    -DLAPACK_LIBRARIES="-l${LBT}" \
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
    -DPKG_GPU=${GPU_OPTION} \
    -DGPU_API=cuda \
    ${cmake_extra_args} \

make -j${nproc}
make install

if [[ "${bb_full_target}" == *mingw* ]]; then
    cp *.dll ${prefix}/bin/
fi

if [[ "${bb_full_target}" != *cuda\+none* && "${bb_full_target}" == *cuda* ]]; then
    unlink $prefix/cuda/lib/libcuda.so
fi
"""

augment_platform_block = """
    using Base.BinaryPlatforms

    module __CUDA
        $(CUDA.augment)
    end

    $(MPI.augment)

    function augment_platform!(platform::Platform)
        augment_mpi!(platform)
        __CUDA.augment_platform!(platform)
    end
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# platforms = supported_platforms(; experimental=true)
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
cuda_platforms = expand_cxxstring_abis(CUDA.supported_platforms(min_version=v"11.0"))
# Cmake toolchain breaks on aarch64, so only x86_64 for now
filter!(p -> arch(p)=="x86_64", cuda_platforms)
mpi_platforms, mpi_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.5.0", OpenMPI_compat="4.1.6, 5")
cudampi_platforms, cudampi_dependencies = MPI.augment_platforms(cuda_platforms; MPItrampoline_compat="5.5.0", OpenMPI_compat="4.1.6, 5")

all_platforms = [platforms; cuda_platforms; mpi_platforms; cudampi_platforms]
for platform in all_platforms
    # Only for the non-CUDA platforms, add the cuda=none tag, if necessary.
    if CUDA.is_supported(platform) && !haskey(platform, "cuda")
        platform["cuda"] = "none"
    end

    # Only for the non-MPI platforms, add the mpi=none tag, if necessary.
    if !haskey(platform, "mpi")
        platform["mpi"] = "none"
    end
end

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
# platforms = filter(p -> !(p["mpi"] == "openmpi" && nbits(p) == 32), platforms)
# MPItrampoline
all_platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), all_platforms)
all_platforms = filter(p -> !(Sys.isfreebsd(p) || libc(p) == "musl"), all_platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("liblammps", :liblammps),
    ExecutableProduct("lmp", :lmp),
]

# Dependencies that must be installed before this package can be built.
# We require CompilerSupportLibraries for the user to have e.g. libgfortran after
# installing this package.
# In addition, we use LLVM OpenMP on BSD systems (OpenBSD & MacOS).
dependencies = AbstractDependency[
    Dependency(
        PackageSpec(;
            name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"
        ),
    ),
    Dependency(
        PackageSpec(; name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
        platforms=filter(Sys.isbsd, platforms),
    ),
    Dependency(
        PackageSpec(;
            name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"
        );
        compat="5.4",
    ),
    Dependency("FFTW_jll"),
]
# Build the tarballs, and possibly a `build.jl` as well.
for platform in all_platforms
    should_build_platform(triplet(platform)) || continue

    _dependencies = copy(dependencies)
    _sources = copy(sources)
    if haskey(platform, "cuda") && platform["cuda"] != "none" && platform["mpi"] != "none"
        append!(_dependencies, cudampi_dependencies)
        append!(_dependencies, CUDA.required_dependencies(platform))
        push!(_dependencies, Dependency(PackageSpec(name="CUDA_Driver_jll")))
    elseif haskey(platform, "cuda") && platform["cuda"] != "none"
        append!(_dependencies, CUDA.required_dependencies(platform))
        push!(_dependencies, Dependency(PackageSpec(name="CUDA_Driver_jll")))
    elseif platform["mpi"] != "none"
        append!(_dependencies, mpi_dependencies)
    end
    build_tarballs(ARGS, name, version, _sources, script, [platform],
                   products, _dependencies;
                   preferred_gcc_version=v"8",
                   julia_compat="1.7",
                   augment_platform_block=augment_platform_block,
                   lazy_artifacts=true
                   )
end
