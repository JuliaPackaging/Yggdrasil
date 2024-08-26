# Note that this script can accept some limited command-line arguments, run                          
# `julia build_tarballs.jl --help` to see a usage message.                                           
using BinaryBuilder, Pkg                                                                             
using Base.BinaryPlatforms                                                                           
const YGGDRASIL_DIR = "../.."                                                                        
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "SIRIUS"
version = v"7.6.0"

sources = [
   GitSource("https://github.com/electronic-structure/SIRIUS/", "21c8fd5019d85ca3181d895e3bc209cb8bba55bb")
]


script = raw"""
apk del cmake

cd $WORKSPACE/srcdir

mkdir build
cd build

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

if [[ "${target}" == *-apple-mpich ]]; then
  CMAKE_ARGS="${CMAKE_ARGS} \
               -DMPI_C_LIB_NAMES='mpi;pmpi;hwloc' \
               -DMPI_CXX_LIB_NAMES='mpicxx;mpi;pmpi;hwloc' \
               -DMPI_mpicxx_LIBRARY=${libdir}/libmpicxx.dylib \
               -DMPI_mpi_LIBRARY=${libdir}/libmpi.dylib \
               -DMPI_pmpi_LIBRARY=${libdir}/libpmpi.dylib \
               -DMPI_hwloc_LIBRARY=${libdir}/libhwloc.dylib"
fi

if [[ "${target}" == *-apple-mpitrampoline ]]; then
  CMAKE_ARGS="${CMAKE_ARGS} \
               -DMPI_C_LIB_NAMES='mpi;pmpi;hwloc' \
               -DMPI_CXX_LIB_NAMES='mpicxx;mpi;pmpi;hwloc' \
               -DMPI_mpicxx_LIBRARY=${libdir}/mpich/lib.libmpicxx.a \
               -DMPI_mpi_LIBRARY=${libdir}/mpich/lib/libmpi.a \
               -DMPI_pmpi_LIBRARY=${libdir}/mpich/lib/libpmpi.a \
               -DMPI_hwloc_LIBRARY=${libdir}/libhwloc.dylib"
fi

#On MacOS, need to explicitly remove the -fallow-argument-mismatch flag, because not recognized by Clang
if [[ "${target}" == *-apple* ]]; then
  CMAKE_ARGS="${CMAKE_ARGS} -DMPI_Fortran_COMPILE_OPTIONS:STRING=''"
fi

#somehow need to run cmake twice for MPI Fortran to work
cmake .. ${CMAKE_ARGS} || cmake .. ${CMAKE_ARGS}

make -j${nproc} install
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
    Dependency("GSL_jll"), 
    Dependency("pugixml_jll"), 
    #Using either MKL or OPENBLAS32
    Dependency("libblastrampoline_jll"),
    Dependency("Libxc_jll"), 
    Dependency("HDF5_jll"),
    Dependency("spglib_jll"), 
    Dependency("spla_jll"), 
    Dependency("SpFFT_jll"), 
    Dependency("COSTA_jll"), 
    Dependency("CompilerSupportLibraries_jll"), 
    Dependency("LLVMOpenMP_jll", platforms=filter(Sys.isapple, platforms)),
    HostBuildDependency(PackageSpec(; name="CMake_jll", version = v"3.28.1"))
]

platforms, platform_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.2.1", OpenMPI_compat="4.1.6, 5")
# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && (Sys.iswindows(p) || libc(p) == "musl")), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version = v"10")
