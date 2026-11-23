# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
include("../common.jl")

name = "SuperLU_DIST"
version = superlu_dist_version

sources = superlu_dist_sources

script = superlu_dist_script(raw"""
if [[ "${target}" == *-mingw* ]]; then
    EXTRA_CMAKE_ARGS+=(-DMPI_HOME=${prefix} -DMPI_GUESS_LIBRARY_NAME=MSMPI)
    if [[ "${target}" == x86_64-* ]]; then
        EXTRA_CMAKE_ARGS+=(-DMPI_C_LIBRARIES=msmpi64 -DMPI_CXX_LIBRARIES=msmpi64)
    fi
fi
""")

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

platforms = supported_platforms()

platforms, platform_dependencies = MPI.augment_platforms(platforms)

products = superlu_dist_products

dependencies = [
    superlu_dist_dependencies...,
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); platforms=filter(Sys.isbsd, platforms)),
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and
# `dlopen`s the shared libraries. (MPItrampoline will skip its
# automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.11", preferred_gcc_version=v"8")
