# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "SpFFT"
version = v"1.1.0"

sources = [
   GitSource("https://github.com/eth-cscs/SpFFT/", "0a0a08c203b311d10d840444886e61c87e2d20f0")
]

script = raw"""
cd $WORKSPACE/srcdir

mkdir build
cd build

CMAKE_ARGS="-DSPFFT_OMP=ON \
            -DSPFFT_MPI=ON \
            -DSPFFT_INSTALL=ON \
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

cmake .. ${CMAKE_ARGS}

make -j${nproc} install

"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""
platforms = supported_platforms()                                                       
filter!(!Sys.iswindows, platforms)
filter!(!Sys.isfreebsd, platforms)
platforms = expand_cxxstring_abis(platforms)

products = [
   LibraryProduct("libspfft", :libspfft)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("FFTW_jll"), 
    Dependency("CompilerSupportLibraries_jll"), 
    Dependency("LLVMOpenMP_jll", platforms=filter(Sys.isapple, platforms)),
]

platforms, platform_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.5.0",
                                                         OpenMPI_compat="4.1.6, 5")
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)

# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)

append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version = v"8")
