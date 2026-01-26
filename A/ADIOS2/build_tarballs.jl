# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "ADIOS2"
upstream_version = v"2.11.0"

# ADIOS2 2.11 is not compatible with ADIOS2 2.10. The C++ bindings differ.
version_offset = v"1.0.2"
version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                        upstream_version.minor * 100 + version_offset.minor,
                        upstream_version.patch * 100 + version_offset.patch)

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ornladios/ADIOS2.git", "a3eb1ab7d713165f457377a925c0c4f3f4dcf0e5"),
    FileSource("https://github.com/user-attachments/files/24653341/ADIOS2-PR4801-PR4804.patch",
               "bbd0445f300d3035c09a193dfeaa86d2910b7e33a25229aa739f4ccf4eb3bb3e"),
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
# # Apply mingw32 fixes; see <https://github.com/ornladios/ADIOS2/issues/4192>
# atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw32.patch
# Avoid run-time checks while cross-building
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/ffs.patch
# Correct library dependencies
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cmakelists.patch
# Correct C includes
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cinttypes.patch

# Add function to determine string length.
# Will probably become unnecessary in the next minor version of ADIOS2.
atomic_patch -p1 ${WORKSPACE}/srcdir/ADIOS2-PR4801-PR4804.patch

# pkg-config is very slow because `abseil_cpp` installed about 200 `*.pc` files.
# Pretend that `protobuf` does not require `abseil_cpp`.
mv /workspace/destdir/lib/pkgconfig/protobuf.pc /workspace/destdir/lib/pkgconfig/protobuf.pc.orig
sed -e 's/Requires/# Requires/' /workspace/destdir/lib/pkgconfig/protobuf.pc.orig >/workspace/destdir/lib/pkgconfig/protobuf.pc

# Fortran is not supported with Clang
# We need `-DADIOS2_Blosc2_PREFER_SHARED=ON` because of <https://github.com/ornladios/ADIOS2/issues/3924>.
cmakeopts=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_FIND_ROOT_PATH=${prefix}
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DBUILD_SHARED_LIBS=ON
    -DBUILD_TESTING=OFF
    -DADIOS2_BUILD_EXAMPLES=OFF
    -DADIOS2_Blosc2_PREFER_SHARED=ON
    -DADIOS2_HAVE_ZFP_CUDA=OFF
    -DADIOS2_INSTALL_GENERATE_CONFIG=OFF
    -DADIOS2_USE_Blosc2=ON
    -DADIOS2_USE_CUDA=OFF
    -DADIOS2_USE_EXTERNAL_NLOHMANN_JSON=ON
    -DADIOS2_USE_EXTERNAL_PUGIXML=ON
    -DADIOS2_USE_EXTERNAL_YAMLCPP=ON
    -DADIOS2_USE_Fortran=OFF
    -DADIOS2_USE_MPI=ON
    -DADIOS2_USE_PNG=ON
    -DADIOS2_USE_ZFP=ON
    -DADIOS2_USE_ZeroMQ=ON
    -DMPI_HOME=${prefix}
)

if [[ ${bb_full_target} == *microsoftmpi* ]]; then
    # Microsoft MPI need special care
    cmakeopts+=(
        -DMPI_C_ADDITIONAL_INCLUDE_DIRS=
        -DMPI_C_LIBRARIES=$l{ibdir}/msmpi.dll
        -DMPI_CXX_ADDITIONAL_INCLUDE_DIRS=
        -DMPI_CXX_LIBRARIES=${libdir}/msmpi.dll
        -DMPI_Fortran_ADDITIONAL_INCLUDE_DIRS=
        -DMPI_Fortran_LIBRARIES=${libdir}/msmpi.dll
    )
fi

if [[ ${bb_full_target} == *mpich* ]]; then
    # This feature only works with MPICH
    cmakeopts+=(
        -DADIOS2_HAVE_MPI_CLIENT_SERVER_EXITCODE=0
        -DADIOS2_HAVE_MPI_CLIENT_SERVER_EXITCODE__TRYRUN_OUTPUT=
    )
else
    cmakeopts+=(
        -DADIOS2_HAVE_MPI_CLIENT_SERVER_EXITCODE=1
        -DADIOS2_HAVE_MPI_CLIENT_SERVER_EXITCODE__TRYRUN_OUTPUT=
    )
fi

# DataMan
if [[ ${target} != *-mingw* ]]; then
    cmakeopts+=(-DADIOS2_USE_DataMan=ON)
fi

# HDF5
if [[ ${target} != *-mingw* ]]; then
    # On Windows, enabling HDF5 leads to the error: `H5VolReadWrite.c:(.text+0x5eb): undefined reference to `H5Pget_fapl_mpio'`
    # We do not build HDF5 for musl
    cmakeopts+=(-DADIOS2_USE_HDF5=ON)
else
    cmakeopts+=(-DADIOS2_USE_HDF5=OFF)
fi

# MGARD
if [[ ${target} != *-mingw* ]]; then
    cmakeopts+=(-DADIOS2_USE_MGARD=ON)
fi

# SST
if [[ ${target} != *-mingw* && ${target} != *-musl* ]]; then
    cmakeopts+=(
        -DADIOS2_USE_SST=ON
        -DADIOS2_SST_HAVE_MPI_DP_HEURISTICS_PASSED_EXITCODE=1   # we assume it fails
        -DADIOS2_SST_HAVE_MPI_DP_HEURISTICS_PASSED_EXITCODE__TRYRUN_OUTPUT=
    )
else
    cmakeopts+=(-DADIOS2_USE_SST=OFF)
fi

export MPITRAMPOLINE_CC=${CC}
export MPITRAMPOLINE_CXX=${CXX}
export MPITRAMPOLINE_FC=${FC}

cmake -Bbuild -GNinja ${cmakeopts[@]}

# Something is wrong with the generated `build.ninja` file on Darwin, don't know why
if [[ ${target} == *-darwin* ]]; then
    sed -i -e 's+-lffi+-L/workspace/destdir/lib -lffi+' build/build.ninja
fi

cmake --build build --parallel ${nproc}
cmake --install build
install_license Copyright.txt LICENSE
"""

sources, script = require_macos_sdk("11.0", sources, script)

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

# There are build errors on Windows, probably fixable
# toolkit/transport/file/FilePOSIX.cpp:448:35: error: ‘pread’ was not declared in this scope
filter!(!Sys.iswindows, platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms)

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
    LibraryProduct("libadios2_cxx", :libadios2_cxx),
    LibraryProduct("libadios2_cxx_mpi", :libadios2_cxx_mpi),

    # Missing on Apple:
    # LibraryProduct("libadios2_taustubs", :libadios2_taustubs),

    # Missing on Windows:
    # LibraryProduct("libadios2_atl", :libadios2_atl),
    # LibraryProduct("libadios2_dill", :libadios2_dill),
    # LibraryProduct("libadios2_evpath", :libadios2_evpath),
    # LibraryProduct("libadios2_ffs", :libadios2_ffs),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Blosc2_jll"); compat="202.2200.0"),
    Dependency(PackageSpec(name="Bzip2_jll"); compat="1.0.9"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="HDF5_jll"); compat="2.0.0"),
    Dependency(PackageSpec(name="Libffi_jll"); compat="~3.4.7"),
    Dependency(PackageSpec(name="MGARD_jll"); compat="1.6.0"),
    Dependency(PackageSpec(name="ZeroMQ_jll"); compat="4.3.6"),
    Dependency(PackageSpec(name="Zstd_jll")),
    Dependency(PackageSpec(name="libpng_jll"); compat="1.6.47"),
    BuildDependency(PackageSpec(name="nlohmann_json_jll")),
    Dependency(PackageSpec(name="protoc_jll")),
    #TODO Dependency(PackageSpec(name="ProtocolBuffers_jll"); compat="3.16.0"),
    Dependency(PackageSpec(name="pugixml_jll"); compat="1.14.1"),
    Dependency(PackageSpec(name="yaml_cpp_jll"); compat="0.8.1"),
    Dependency(PackageSpec(name="zfp_jll"); compat="1.0.2"),
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and
# `dlopen`s the shared libraries. (MPItrampoline will skip its
# automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs, and possibly a `build.jl` as well.
# GCC 4 is too old for Windows; it doesn't have <regex.h>
# GCC 5 is too old for FreeBSD; it doesn't have `std::to_string`
# GCC 6 is too old; it doesn't have `std::optional`
# GCC 7 is too old; it doesn't handle `std::thread(std::memcpy, ...)`
# GCC 8 is too old; it requires explicitly linking for using `std::filesystem`
# We need MacOS SDK 11.0 for `std::filesystem`
# We need Julia 1.8 or later so that HDF5_jll is working
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.8", preferred_gcc_version=v"9")
