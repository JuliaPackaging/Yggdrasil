# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "ADIOS2"
adios2_version = v"2.10.2"
version = v"2.10.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ornladios/ADIOS2.git", "a19dad6cecb00319825f20fd9f455ebbab903d34"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/ADIOS2

# Don't define clock_gettime on macOS
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/clock_gettime.patch
# Declare `arm8_rt_call_link`. See <https://github.com/ornladios/ADIOS2/issues/3925>.
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/arm8_rt_call_link.patch
# Declare `htons`. See <https://github.com/ornladios/ADIOS2/issues/3926>.
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/htons.patch
# Apply mingw32 fixes; see <https://github.com/ornladios/ADIOS2/issues/4192>
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw32.patch

if [[ ${target} == x86_64-linux-musl ]]; then
    # HDF5 needs libcurl, and it needs to be the BinaryBuilder libcurl, not the system libcurl.
    # MPI needs libevent, and it needs to be the BinaryBuilder libevent, not the system libevent.
    rm /usr/lib/libcurl.*
    rm /usr/lib/libevent*
    rm /usr/lib/libnghttp2.*
fi

archopts=()

if grep -q MPICH_NAME ${prefix}/include/mpi.h && ls /usr/include/*/sys/queue.hh >/dev/null 2>&1; then
    # This feature only works with MPICH
    archopts+=(-DADIOS2_HAVE_MPI_CLIENT_SERVER_EXITCODE=0 -DADIOS2_HAVE_MPI_CLIENT_SERVER_EXITCODE__TRYRUN_OUTPUT=)
else
    archopts+=(-DADIOS2_HAVE_MPI_CLIENT_SERVER_EXITCODE=1 -DADIOS2_HAVE_MPI_CLIENT_SERVER_EXITCODE__TRYRUN_OUTPUT=)
fi

if grep -q MSMPI_VER ${includedir}/mpi.h; then
    # Microsoft MPI
    archopts+=(-DMPI_C_ADDITIONAL_INCLUDE_DIRS= -DMPI_C_LIBRARIES=$l{ibdir}/msmpi.dll
               -DMPI_CXX_ADDITIONAL_INCLUDE_DIRS= -DMPI_CXX_LIBRARIES=${libdir}/msmpi.dll
               -DMPI_Fortran_ADDITIONAL_INCLUDE_DIRS= -DMPI_Fortran_LIBRARIES=${libdir}/msmpi.dll)
fi

if [[ "${target}" == *-mingw* ]]; then
    # Windows: Some options do not build
    # Enabling HDF5 leads to the error: `H5VolReadWrite.c:(.text+0x5eb): undefined reference to `H5Pget_fapl_mpio'`
    archopts+=(-DADIOS2_USE_DataMan=OFF -DADIOS2_USE_SST=OFF -DEVPATH_TRANSPORT_MODULES=OFF)
else
    archopts+=(-DADIOS2_USE_DataMan=ON -DADIOS2_USE_SST=ON)
fi

# Use HDF5 if it is available
if [ -e ${libdir}/libhdf5.${dlext} ]; then
    archopts+=(-DADIOS2_USE_HDF5=ON)
else
    archopts+=(-DADIOS2_USE_HDF5=OFF)
fi

# Use MGARD if it is available
if [ -e ${libdir}/libmgard.${dlext} ]; then
    archopts+=(-DADIOS2_USE_MGARD=ON)
else
    archopts+=(-DADIOS2_USE_MGARD=OFF)
fi

export MPITRAMPOLINE_CC=${CC}
export MPITRAMPOLINE_CXX=${CXX}
export MPITRAMPOLINE_FC=${FC}

# Fortran is not supported with Clang
# We need `-DADIOS2_Blosc2_PREFER_SHARED=ON` because of <https://github.com/ornladios/ADIOS2/issues/3924>.
cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TESTING=OFF \
    -DADIOS2_BUILD_EXAMPLES=OFF \
    -DADIOS2_HAVE_ZFP_CUDA=OFF \
    -DADIOS2_USE_Blosc2=ON \
    -DADIOS2_Blosc2_PREFER_SHARED=ON \
    -DADIOS2_USE_CUDA=OFF \
    -DADIOS2_USE_Fortran=OFF \
    -DADIOS2_USE_MPI=ON \
    -DADIOS2_USE_PNG=ON \
    -DADIOS2_USE_ZeroMQ=ON \
    -DADIOS2_INSTALL_GENERATE_CONFIG=OFF \
    -DMPI_HOME=${prefix} \
    ${archopts[@]}
cmake --build build --parallel ${nproc}
cmake --install build
install_license Copyright.txt LICENSE
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# 32-bit architectures are not supported; see
# <https://github.com/ornladios/ADIOS2/issues/2704>
filter!(p -> nbits(p) ≠ 32, platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# We don't need HDF5 on Windows (see above)
hdf5_platforms = filter(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    # ExecutableProduct("adios_deactivate_bp", :adios_deactivate_bp),
    # ExecutableProduct("adios_iotest", :adios_iotest),
    # ExecutableProduct("adios_reorganize", :adios_reorganize),
    # ExecutableProduct("adios_reorganize_mpi", :adios_reorganize_mpi),
    # ExecutableProduct("bp4dbg", :bp4dbg),
    ExecutableProduct("bpls", :bpls),
    # ExecutableProduct("sst_conn_tool", :sst_conn_tool),

    LibraryProduct("libadios2_c", :libadios2_c),
    LibraryProduct("libadios2_c_mpi", :libadios2_c_mpi),
    LibraryProduct("libadios2_core", :libadios2_core),
    LibraryProduct("libadios2_core_mpi", :libadios2_core_mpi),
    LibraryProduct("libadios2_cxx11", :libadios2_cxx11),
    LibraryProduct("libadios2_cxx11_mpi", :libadios2_cxx11_mpi),

    # Missing on Apple:
    # LibraryProduct("libadios2_taustubs", :libadios2_taustubs),

    # Missing on Windows:
    # LibraryProduct("libadios2_atl", :libadios2_atl),
    # LibraryProduct("libadios2_dill", :libadios2_dill),
    # LibraryProduct("libadios2_evpath", :libadios2_evpath),
    # LibraryProduct("libadios2_ffs", :libadios2_ffs),
]

# Dependencies that must be installed before this package can be built
# - We currently need to disable MGARD. It seems that MGARD uses Zstd,
#   and the ADIOS2 build system cannot handle this.
dependencies = [
    Dependency(PackageSpec(name="Blosc2_jll"); compat="201.1700.0"),
    Dependency(PackageSpec(name="Bzip2_jll"); compat="1.0.9"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="HDF5_jll"); compat="~1.14.6", platforms=hdf5_platforms),
    # Dependency(PackageSpec(name="MGARD_jll"); compat="1.5.2"),
    Dependency(PackageSpec(name="ZeroMQ_jll")),
    # Dependency(PackageSpec(name="Zstd_jll")),
    Dependency(PackageSpec(name="libpng_jll")),
    Dependency(PackageSpec(name="protoc_jll")),
    Dependency(PackageSpec(name="pugixml_jll")),
    Dependency(PackageSpec(name="yaml_cpp_jll")),
    Dependency(PackageSpec(name="zfp_jll"); compat="1.0.1"),
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and
# `dlopen`s the shared libraries. (MPItrampoline will skip its
# automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs, and possibly a `build.jl` as well.
# GCC 4 is too old for Windows; it doesn't have <regex.h>
# GCC 5 is too old for FreeBSD; it doesn't have `std::to_string`
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"6")
