# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg, BinaryBuilderBase
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "C", "CUDA", "common.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
include("../common.jl")

name = "SuperLU_DIST_CUDA"
version = superlu_dist_version
# The renamed libraries and the CUDA_Runtime_jll bound need a new JLL version
ygg_version = v"9.3.3"

sources = superlu_dist_sources

script = superlu_dist_script(raw"""
# own SONAMEs, so that dependents don't bind to SuperLU_DIST_jll's when both are loaded
SUPERLU_SUFFIX=_cuda

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/findcudatoolkit.patch

# nvcc writes to /tmp, which is a small tmpfs in the sandbox.
export TMPDIR=${WORKSPACE}/tmpdir
mkdir -v ${TMPDIR}

# BinaryBuilder's x86_64 host needs x86_64 CUDA tools to cross compile for aarch64.
# nvvm is inside the nvcc archive before CUDA 13, and in its own archive after.
if [[ "${target}" == aarch64-* ]]; then
    export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:${LD_LIBRARY_PATH}"
    export NVCC_PREPEND_FLAGS="-ccbin=${CXX}"
    rm -rfv ${prefix}/cuda/bin ${prefix}/cuda/nvvm/bin ${prefix}/cuda/nvvm/lib64
    cp -a ${WORKSPACE}/srcdir/cuda_nvcc-linux-x86_64-*-archive/bin ${prefix}/cuda/bin
    cp -a ${WORKSPACE}/srcdir/*-linux-x86_64-*-archive/nvvm/{bin,lib64} ${prefix}/cuda/nvvm/
fi

EXTRA_CMAKE_ARGS+=(
    -DTPL_ENABLE_CUDALIB=ON
    -DCMAKE_CUDA_COMPILER=${prefix}/cuda/bin/nvcc
    -DCMAKE_CUDA_FLAGS="-L${prefix}/cuda/lib"
    -DCMAKE_CUDA_ARCHITECTURES="${CUDA_ARCHS}"
    # CUDA 13's cuBLASLt and cuSOLVER need a newer glibc than the sysroot's, which
    # only breaks linking the pdtest executables.
    -DCMAKE_EXE_LINKER_FLAGS="-Wl,--allow-shlib-undefined"
)
""") * raw"""
# The swapped-in x86_64 tools would otherwise be packaged.
if [[ "${target}" == aarch64-* ]]; then
    rm -rfv ${prefix}/cuda
fi
# The x86_64 CUDA archives in srcdir stop auto_install_license from finding it.
install_license License.txt
"""

platforms = CUDA.supported_platforms(; min_version=v"12")
# An artifact also matches newer toolkits of its major, whose newer GPUs would have to JIT-compile
# the PTX of its newest architecture. 12.8 adds sm_100, sm_101 and sm_120, and 12.9 adds sm_103 and
# sm_121.
filter!(p -> Base.thisminor(VersionNumber(p["cuda"])) in (v"12.0", v"12.8", v"12.9", v"13.0"), platforms)

platforms, mpi_dependencies = MPI.augment_platforms(platforms)

# MPICH is the default without an MPI preference, and MPIABI's library can be replaced at
# runtime. The default GPU 3D factorization passes device pointers to MPI_Bcast, so multi-rank
# runs need a CUDA-aware MPI at runtime, or GPU3DVERSION=0.
filter!(p -> p["mpi"] in ("mpiabi", "mpich"), platforms)

augment_platform_block = CUDA.augment_with(MPI.augment, "augment_mpi!")

products = [
    ExecutableProduct("pdtest_32", :pdtest_32),
    ExecutableProduct("pdtest_64", :pdtest_64),

    LibraryProduct("libsuperlu_dist_cuda_Int32", :libsuperlu_dist_Int32),
    LibraryProduct("libsuperlu_dist_cuda_Int64", :libsuperlu_dist_Int64),
]

dependencies = AbstractDependency[
    superlu_dist_dependencies...,
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); compat="1.0.5"),
    mpi_dependencies...,
    CUDA.required_dependencies(platforms; static_sdk=true)...,
]

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    platform_sources = BinaryBuilder.AbstractSource[sources...]
    if arch(platform) == "aarch64"
        cuda_ver = VersionNumber(platform["cuda"])
        components = ["cuda_nvcc"]
        cuda_ver >= v"13" && push!(components, "libnvvm")
        x86_platform = deepcopy(platform)
        x86_platform["arch"] = "x86_64"
        append!(platform_sources, get_sources("cuda", components;
                                              version=CUDA.full_version(cuda_ver),
                                              platform=x86_platform))
    end

    platform_script = "CUDA_ARCHS=\"$(CUDA.cuda_gpu_archs_cmake(platform))\"\n" * script

    build_tarballs(ARGS, name, ygg_version, platform_sources, platform_script, [platform],
                   products, dependencies; lazy_artifacts=true,
                   augment_platform_block, julia_compat="1.11",
                   dont_dlopen=true, preferred_gcc_version=v"8")
end
