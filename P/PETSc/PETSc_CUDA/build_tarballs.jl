using BinaryBuilder, BinaryBuilderBase, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "C/CUDA/common.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
include(joinpath(@__DIR__, "..", "common.jl"))

name = "PETSc_CUDA"
version = petsc_version
ygg_version = v"3.25.8"  # compat changes need a new JLL version

sources = petsc_sources(; cuda=true)

# BinaryBuilder's x86_64 host needs x86_64 CUDA tools to cross compile for aarch64.
# nvvm is inside the nvcc archive before CUDA 13, and in its own archive after.
# PETSc passes its C++ compiler to nvcc as -ccbin itself.
script = raw"""
if [[ "${target}" == aarch64-* ]]; then
    export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:${LD_LIBRARY_PATH}"
    rm -rfv ${prefix}/cuda/bin ${prefix}/cuda/nvvm/bin ${prefix}/cuda/nvvm/lib64
    cp -a ${WORKSPACE}/srcdir/cuda_nvcc-linux-x86_64-*-archive/bin ${prefix}/cuda/bin
    cp -a ${WORKSPACE}/srcdir/*-linux-x86_64-*-archive/nvvm/{bin,lib64} ${prefix}/cuda/nvvm/
    atomic_patch -p1 -d ${WORKSPACE}/srcdir/petsc-* ${WORKSPACE}/srcdir/patches/nvcc-fp16.patch
fi
""" * petsc_script(cuda_preamble, raw"""build_petsc double real    Int64 opt
build_petsc double real    Int32 opt

# The swapped-in x86_64 tools would otherwise be packaged.
if [[ "${target}" == aarch64-* ]]; then
    rm -r ${prefix}/cuda
fi""")

platforms = CUDA.supported_platforms(; min_version=v"12")

# The toolkits that add GPU architectures (PETSc embeds no PTX for newer GPUs). These are also
# the ones SuperLU_DIST_CUDA_jll is built for, whose artifacts must match the `cuda` tag exactly.
filter!(p -> Base.thisminor(VersionNumber(p["cuda"])) in (v"12.0", v"12.8", v"12.9", v"13.0"), platforms)

platforms = expand_gfortran_versions(platforms)
platforms = expand_cxxstring_abis(platforms)
platforms, platform_dependencies = MPI.augment_platforms(platforms)

# The MPI ABIs SuperLU_DIST_CUDA_jll is built for
filter!(p -> p["mpi"] in ("mpiabi", "mpich"), platforms)

augment_platform_block = CUDA.augment_with(MPI.augment, "augment_mpi!")

products = [
    ExecutableProduct("ex4", :ex4),
    ExecutableProduct("ex42", :ex42),
    ExecutableProduct("ex19", :ex19),
    ExecutableProduct("ex19_int32", :ex19_int32),
    LibraryProduct("libpetsc_double_real_Int64", :libpetsc, "\$libdir/petsc/double_real_Int64/lib"; dont_dlopen=true),
    LibraryProduct("libpetsc_double_real_Int64", :libpetsc_Float64_Real_Int64, "\$libdir/petsc/double_real_Int64/lib"; dont_dlopen=true),
    LibraryProduct("libpetsc_double_real_Int32", :libpetsc_Float64_Real_Int32, "\$libdir/petsc/double_real_Int32/lib"; dont_dlopen=true),
]

dependencies = petsc_dependencies(platforms; superlu_cuda=true)
push!(dependencies, Dependency(PackageSpec(name="NVTX_jll"); compat="3.2.2"))
append!(dependencies, platform_dependencies)
append!(dependencies, CUDA.required_dependencies(platforms))

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
    platform_script = "CUDA_ARCHS=\"$(join(CUDA.cuda_gpu_archs(platform), ","))\"\n" * script
    # nvcc rejects a host GCC newer than the toolkit supports: CUDA < 12.4 caps out below
    # Yggdrasil's GCC 13.2, and CUDA 13's CCCL needs the C++17 default of GCC >= 12.
    gcc_version = VersionNumber(platform["cuda"]) < v"12.4" ? v"12" : v"13"
    build_tarballs(ARGS, name, ygg_version, platform_sources, platform_script, [platform], products, dependencies;
                   augment_platform_block, julia_compat="1.12", preferred_gcc_version=gcc_version,
                   lazy_artifacts=true, dont_dlopen=true)
end
