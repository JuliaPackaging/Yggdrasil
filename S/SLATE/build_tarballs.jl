using BinaryBuilder
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "SLATE"
version = v"2022.05.01"
slate_version = v"2022.05.00"

# Collection of sources required to build PETSc. Avoid using the git repository, it will
# require building SOWING which fails in all non-linux platforms.
sources = [
    GitSource("https://github.com/icl-utk-edu/slate.git", "0e5cadfd97c72e22a1b35e994487cfc3e65c9b2e")
]

# Bash recipe for building across all platforms

# Needs to add -Dcapi eventually once it's added to the cmake build system. Note yet available under CMAKAE toolchain.
script = raw"""
cd slate
git submodule update --init
mkdir build && cd build
BLAS=blastrampoline
LAPACK=blastrampoline
GPU=none
if  [[ $bb_full_target == *-linux*cuda+1* ]]; then
    # nvcc writes to /tmp, which is a small tmpfs in our sandbox.
    # make it use the workspace instead
    export TMPDIR=${WORKSPACE}/tmpdir
    mkdir ${TMPDIR}
    export CUDA_HOME=${WORKSPACE}/destdir/cuda
    export PATH=$PATH:$CUDA_HOME/bin
    export GPU=cuda
fi
# Dblas_int=int64 disabled since it's very new and not every downstream supports
cmake \
  -DCMAKE_INSTALL_PREFIX=${prefix} \
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
  -DCMAKE_BUILD_TYPE="Release" \
  -Dblas_complex_return="return" \
  -Dblas_return_float_f2c=yes \
  -Drun_result="0" \
  -Drun_result__TRYRUN_OUTPUT="ok" \
  -Dgpu_backend="${GPU}" \
  -Dbuild_tests=no \
  -DBLAS_LIBRARIES="-l${BLAS}" \
  -DLAPACK_LIBRARIES="-l${LAPACK}" \
  -DMPI_RUN_RESULT_CXX_libver_mpi_normal="0" \
  -DMPI_RUN_RESULT_CXX_libver_mpi_normal__TRYRUN_OUTPUT="" \
  -Dc_api=yes \
  ..

make -j${nproc}
make install
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    $(CUDA.augment)
    augment_platform!(platform::Platform) = (augment_mpi!(augment_platform!(platform))
"""

versions_to_build = [
    nothing,
    v"11.0",
    v"12.0", 
]

# XXX: support only specifying major/minor version (JuliaPackaging/BinaryBuilder.jl#/1212)
cuda_full_versions = Dict(
    v"11.0" => v"11.0.3",
    v"12.0" => v"12.0.1",
)


# We attempt to build for all defined platforms
platforms = expand_gfortran_versions(expand_cxxstring_abis(supported_platforms()))
platforms = filter(p -> libgfortran_version(p) ≠ v"3", platforms)

platforms, mpi_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.2.1")
# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

products = [
    LibraryProduct("libslate", :libslate),
    LibraryProduct("libslate_lapack_api", :libslate_lapack_api)
    # LibraryProduct("libslate_scalapack_api, :libslate_scalapack_api) ** Not yet available under CMAKE toolchain.
]

for cuda_version in versions_to_build, platform in platforms
    build_cuda = (os(platform) == "linux") && (arch(platform) in ["x86_64"])
    if !isnothing(cuda_version) && !build_cuda
        continue
    end

    augmented_platform = Platform(arch(platform), os(platform);
        cuda=isnothing(cuda_version) ? "none" : CUDA.platform(cuda_version)
    )
    should_build_platform(triplet(augmented_platform)) || continue

    dependencies = [
        Dependency("CompilerSupportLibraries_jll"),
        Dependency("libblastrampoline_jll"),
    ]
    append!(dependencies, mpi_dependencies)

    if !isnothing(cuda_version)
        push!(dependencies, BuildDependency(PackageSpec(name="CUDA_full_jll", version=cuda_full_versions[cuda_version])))
        push!(dependencies, RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll")))
    end
    
    build_tarballs(ARGS, name, version, sources, script, [augmented_platform], products, dependencies; 
                    preferred_gcc_version=v"8", 
                    julia_compat="1.6",
                    augment_platform_block)
end