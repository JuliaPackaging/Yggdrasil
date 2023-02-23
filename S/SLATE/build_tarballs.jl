using BinaryBuilder
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "SLATE"
version = v"2022.05.01"
slate_version = v"2022.05.00"

# Collection of sources required to build PETSc. Avoid using the git repository, it will
# require building SOWING which fails in all non-linux platforms.
sources = [
    GitSource("https://bitbucket.org/icl/slate.git", "5fb57877effa06d2ef090402a39341ebeb44f180")
]

# Bash recipe for building across all platforms

# Needs to add -Dcapi eventually once it's added to the cmake build system. Note yet available under CMAKAE toolchain.
script = raw"""
cd slate
git submodule update --init
mkdir build && cd build
cmake \
  -DCMAKE_INSTALL_PREFIX=${prefix} \
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
  -DCMAKE_BUILD_TYPE="Release" \
  -Dblas=openblas \
  -Dbuild_tests=no \
  -DMPI_RUN_RESULT_CXX_libver_mpi_normal="0" \
  -DMPI_RUN_RESULT_CXX_libver_mpi_normal__TRYRUN_OUTPUT="" \
  -Drun_result="0" \
  -Drun_result__TRYRUN_OUTPUT="ok" \
  -Dc_api=yes \
  ..
make -j${nproc}
make install
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# We attempt to build for all defined platforms
platforms = expand_gfortran_versions(expand_cxxstring_abis(supported_platforms(; exclude=!Sys.islinux)))
platforms = filter(p -> libgfortran_version(p) ≠ v"3", platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms)

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

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS32_jll"),
]
append!(dependencies, platform_dependencies)

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"7")
