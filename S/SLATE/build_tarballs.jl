using BinaryBuilder
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "SLATE"
version = v"2025.05.28"

sources = [
    GitSource("https://github.com/icl-utk-edu/slate.git", "f8348a7c3de4f8fc60f5b8f78134df25ebc9061b"),
    DirectorySource(joinpath(@__DIR__, "bundled")),
]

script = raw"""
cd slate
git submodule update --init

export CXXFLAGS="${CXXFLAGS:-} -std=c++17"

atomic_patch -p1 ../patches/fix-std-function-signatures.patch

mkdir build && cd build

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_BUILD_TYPE="Release"
    -DCMAKE_CXX_STANDARD=17
    -DCMAKE_CXX_STANDARD_REQUIRED=ON
    -DCMAKE_CXX_EXTENSIONS=OFF
    -DBUILD_SHARED_LIBS=ON
    -Dblas=openblas
    -Dgpu_backend=none
    -Dbuild_tests=no
    -DMPI_RUN_RESULT_CXX_libver_mpi_normal="0"
    -DMPI_RUN_RESULT_CXX_libver_mpi_normal__TRYRUN_OUTPUT=""
    -Drun_result="0"
    -Drun_result__TRYRUN_OUTPUT="ok"
    -Dblas_complex_return=return
    -Dblas_int=int
)

cmake "${CMAKE_FLAGS[@]}" ..
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
platforms, platform_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.3.1", OpenMPI_compat="4.1.6, 5")
platforms = filter(p -> libgfortran_version(p) ≠ v"3", platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

products = [
    LibraryProduct("libslate", :libslate),
    LibraryProduct("libslate_lapack_api", :libslate_lapack_api),
    # LibraryProduct("libslate_scalapack_api, :libslate_scalapack_api) ** Not yet available under CMAKE toolchain.
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS32_jll"),
]
append!(dependencies, platform_dependencies)

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version = v"10")
