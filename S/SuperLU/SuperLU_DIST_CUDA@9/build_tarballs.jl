# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg, BinaryBuilderBase
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
include("../common.jl")

name = "SuperLU_DIST_CUDA"
version = superlu_dist_version

sources = superlu_dist_sources

script = superlu_dist_script(raw"""
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/findcudatoolkit.patch

# nvcc writes to /tmp, which is a small tmpfs in the sandbox.
export TMPDIR=${WORKSPACE}/tmpdir
mkdir -v ${TMPDIR}

EXTRA_CMAKE_ARGS+=(
    -DTPL_ENABLE_CUDALIB=ON
    -DCMAKE_CUDA_COMPILER=${prefix}/cuda/bin/nvcc
    -DCMAKE_CUDA_FLAGS="-L${prefix}/cuda/lib"
    -DCMAKE_CUDA_ARCHITECTURES="${CUDA_ARCHS}"
    # CUDA 13's cuBLASLt and cuSOLVER need a newer glibc than the sysroot's, which
    # only breaks linking the pdtest executables.
    -DCMAKE_EXE_LINKER_FLAGS="-Wl,--allow-shlib-undefined"
)
""")

# aarch64 would need the host x86_64 nvcc swapped in, as A/AMGX/AMGX_MPI does.
platforms = CUDA.supported_platforms(; min_version=v"12")
filter!(p -> arch(p) == "x86_64", platforms)

platforms, mpi_dependencies = MPI.augment_platforms(platforms)

# Only MPIABI, whose library can be replaced at runtime. Every ABI would multiply
# the CUDA matrix by four. The default GPU 3D factorization passes device pointers
# to MPI_Bcast, so multi-rank runs need a CUDA-aware MPI at runtime, or GPU3DVERSION=0.
filter!(p -> p["mpi"] == "mpiabi", platforms)

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

products = superlu_dist_products

dependencies = AbstractDependency[
    superlu_dist_dependencies...,
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); compat="1.0.5"),
]
append!(dependencies, mpi_dependencies)

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    platform_dependencies = [dependencies; CUDA.required_dependencies(platform; static_sdk=true)]
    platform_script = "CUDA_ARCHS=\"$(join(CUDA.cuda_gpu_archs(platform), ";"))\"\n" * script

    build_tarballs(ARGS, name, version, sources, platform_script, [platform],
                   products, platform_dependencies; lazy_artifacts=true,
                   augment_platform_block, julia_compat="1.11",
                   dont_dlopen=true, preferred_gcc_version=v"8")
end
