# Note that this script can accept some limited command-line arguments, run                          
# `julia build_tarballs.jl --help` to see a usage message.                                           
using BinaryBuilder, Pkg                                                                             
using Base.BinaryPlatforms                                                                           
const YGGDRASIL_DIR = "../.."                                                                        
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "SIRIUS"
version = v"7.6.1"

sources = [
   GitSource("https://github.com/electronic-structure/SIRIUS.git",
             "63202622b85f0c5ac5d7a6d66ab21adb6dd573cd")
]


script = raw"""
apk del cmake

cd $WORKSPACE/srcdir/SIRIUS

#For GSL to be correctly linked to cblas
export LDFLAGS="-lgsl -lgslcblas -lblastrampoline"

CMAKE_ARGS="-DSIRIUS_CREATE_FORTRAN_BINDINGS=ON \
            -DSIRIUS_USE_OPENMP=ON \
            -DSIRIUS_USE_PUGIXML=ON \
            -DSIRIUS_USE_MEMORY_POOL=OFF \
            -DSIRIUS_BUILD_APPS=OFF \
            -DSIRIUS_USE_PROFILER=OFF \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            -DCMAKE_FIND_ROOT_PATH='${prefix}/lib/mpich;${prefix}' \
            -DCMAKE_INSTALL_PREFIX=$prefix \
            -DCMAKE_BUILD_TYPE=Release \
            -DBUILD_SHARED_LIBS=ON \
            -DMPI_C_COMPILER=$bindir/mpicc \
            -DMPI_CXX_COMPILER=$bindir/mpicxx"

#need to pass various results of CMake's try_run() for MPI compilers for succesful build
CMAKE_ARGS="${CMAKE_ARGS} -DMPI_RUN_RESULT_C_libver_mpi_normal=0 \
                          -DMPI_RUN_RESULT_C_libver_mpi_normal__TRYRUN_OUTPUT='' \
                          -DMPI_RUN_RESULT_CXX_libver_mpi_normal=0 \
                          -DMPI_RUN_RESULT_CXX_libver_mpi_normal__TRYRUN_OUTPUT='' \
                          -DMPI_RUN_RESULT_Fortran_libver_mpi_F90_MODULE=0 \
                          -DMPI_RUN_RESULT_Fortran_libver_mpi_F90_MODULE__TRYRUN_OUTPUT='' \
                          -DMPI_RUN_RESULT_Fortran_libver_mpi_F08_MODULE=0 \
                          -DMPI_RUN_RESULT_Fortran_libver_mpi_F08_MODULE__TRYRUN_OUTPUT=''"

cmake -B build ${CMAKE_ARGS}

#On MacOS, need to explicitly remove the -fallow-argument-mismatch flag, because not recognized by Clang
if [[ "${target}" == *-apple* ]]; then
   cmake -B build "-DMPI_Fortran_COMPILE_OPTIONS=''"
fi

cmake --build build --parallel ${nproc}
cmake --install build
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""
platforms = [Platform("x86_64", "linux"), Platform("aarch64", "linux"), Platform("aarch64", "macos")]
filter!(p -> !(libc(p) == "musl"), platforms)
platforms = expand_cxxstring_abis(platforms)

platforms = expand_gfortran_versions(platforms)
filter!(p -> !(libgfortran_version(p) < v"5"), platforms)

products = [
   LibraryProduct("libsirius", :libsirius)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GSL_jll"; compat="~2.7.2"),
    Dependency("pugixml_jll"),
    #Using either MKL or OPENBLAS32
    Dependency("libblastrampoline_jll"; compat="5.4.0"),
    Dependency("Libxc_jll"),
    # We had to restrict compat with HDF5 because of ABI breakage:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/10347#issuecomment-2662923973
    # Updating to a newer HDF5 version is likely possible without problems but requires rebuilding this package
    Dependency("HDF5_jll"; compat="=1.14.3"),
    Dependency("spglib_jll"),
    Dependency("spla_jll"),
    Dependency("SpFFT_jll"),
    Dependency("COSTA_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("LLVMOpenMP_jll", platforms=filter(Sys.isapple, platforms)),
    HostBuildDependency(PackageSpec(; name="CMake_jll", version = v"3.28.1"))
]

platforms, platform_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.3.1", OpenMPI_compat="4.1.6, 5")
# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline"), platforms) #HDF5 incompatibility with v5.3.1

append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.9", preferred_gcc_version = v"10")
