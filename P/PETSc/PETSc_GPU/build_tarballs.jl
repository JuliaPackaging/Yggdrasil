using BinaryBuilder, BinaryBuilderBase, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "C/CUDA/common.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
include(joinpath(@__DIR__, "..", "common.jl"))

name = "PETSc_GPU"
version = petsc_version

sources = petsc_sources(; cuda=true)

script = petsc_script(cuda_preamble, raw"""build_petsc double real    Int64 opt
build_petsc double real    Int32 opt""")

platforms = CUDA.supported_platforms(; min_version=v"12")

# aarch64 would need the host x86_64 nvcc swapped in; PETSc's configure cannot do that
filter!(p -> arch(p) == "x86_64", platforms)

platforms = expand_gfortran_versions(platforms)
platforms = expand_cxxstring_abis(platforms)
platforms, platform_dependencies = MPI.augment_platforms(platforms)

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

products = [
    ExecutableProduct("ex4", :ex4),
    ExecutableProduct("ex42", :ex42),
    ExecutableProduct("ex19", :ex19),
    ExecutableProduct("ex19_int32", :ex19_int32),
    LibraryProduct("libpetsc_double_real_Int64", :libpetsc, "\$libdir/petsc/double_real_Int64/lib"; dont_dlopen=true),
    LibraryProduct("libpetsc_double_real_Int64", :libpetsc_Float64_Real_Int64, "\$libdir/petsc/double_real_Int64/lib"; dont_dlopen=true),
    LibraryProduct("libpetsc_double_real_Int32", :libpetsc_Float64_Real_Int32, "\$libdir/petsc/double_real_Int32/lib"; dont_dlopen=true),
]

dependencies = petsc_dependencies(platforms)
push!(dependencies, Dependency(PackageSpec(name="NVTX_jll"); compat="3.2.2"))
append!(dependencies, platform_dependencies)

for platform in platforms
    should_build_platform(triplet(platform)) || continue
    deps = AbstractDependency[dependencies...]
    append!(deps, CUDA.required_dependencies(platform))
    platform_script = "CUDA_ARCHS=\"$(join(CUDA.cuda_gpu_archs(platform), ","))\"\n" * script
    # nvcc rejects a host GCC newer than the toolkit supports: CUDA < 12.4 caps out below
    # Yggdrasil's GCC 13.2, and CUDA 13's CCCL needs the C++17 default of GCC >= 12.
    gcc_version = VersionNumber(platform["cuda"]) < v"12.4" ? v"12" : v"13"
    build_tarballs(ARGS, name, version, sources, platform_script, [platform], products, deps;
                   augment_platform_block, julia_compat="1.12", preferred_gcc_version=gcc_version,
                   lazy_artifacts=true, dont_dlopen=true)
end
