# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "openPMD_api_C"
version = v"0.15.2" # This is really the branch `eschnett/c-bindings` after version 0.15.2

# Collection of sources required to complete build
sources = [
    # We use a feature branch instead of a released version because the C bindings are not released yet
    GitSource("https://github.com/eschnett/openPMD-api.git", "137488c1914aa1e4b22c8b638935a41355f07739"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
]

# Bash recipe for building across all platforms
script = raw"""
# Log which MPI implementation is actually used
grep -iq MPICH ${includedir}/mpi.h && echo 'MPI: MPICH'
grep -iq MPItrampoline ${includedir}/mpi.h && echo 'MPI: MPItrampoline'
grep -iq MSMPI_VER ${includedir}/mpi.h && echo 'MPI: MicrosoftMPI'
grep -iq OpenMPI ${includedir}/mpi.h && echo 'MPI: OpenMPI'

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Work around the issue
    #     /workspace/srcdir/SHOT/src/Model/../Model/Simplifications.h:1370:26: error: 'value' is unavailable: introduced in macOS 10.14
    #                     optional.value()->coefficient *= -1.0;
    #                              ^
    #     /opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root/usr/include/c++/v1/optional:947:27: note: 'value' has been explicitly marked unavailable here
    #         constexpr value_type& value() &
    #                               ^
    export MACOSX_DEPLOYMENT_TARGET=10.15
    # ...and install a newer SDK which supports `std::filesystem`
    pushd ${WORKSPACE}/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -a usr/* /opt/${target}/${target}/sys-root/usr/
    cp -a System /opt/${target}/${target}/sys-root/
    popd
fi

cd ${WORKSPACE}/srcdir
cd openPMD-api

archopts=()
if [[ "${target}" == x86_64-w64-mingw32 ]]; then
    # Microsoft MPI
    archopts+=(
        -DMPI_C_ADDITIONAL_INCLUDE_DIRS=
        -DMPI_C_LIBRARIES=${libdir}/msmpi.dll
        -DMPI_CXX_ADDITIONAL_INCLUDE_DIRS=
        -DMPI_CXX_LIBRARIES=${libdir}/msmpi.dll)
fi
if [[ "${target}" == *-mingw32 ]]; then
    # Windows: We do not have a parallel HDF5 implementation there
    archopts+=(-DopenPMD_USE_HDF5=OFF)
else
    archopts+=(-DopenPMD_USE_HDF5=ON)
fi

cmake -B build -S . \
    -DBUILD_CLI_TOOLS=ON \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DMPI_HOME=${prefix} \
    -DopenPMD_USE_C=ON \
    -DopenPMD_USE_MPI=ON \
    ${archopts[@]}
cmake --build build --parallel ${nproc}
cmake --install build

install_license COPYING*
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

platforms, platform_dependencies = MPI.augment_platforms(platforms; MPItrampoline_compat="5.3.0")

# The shared libraries are installed wrong on Windows. I think they
# are installed into `lib` instead of into `bin`. I think this could
# be fixed. Until then...
platforms = filter(!Sys.iswindows, platforms)

# Avoid platforms where the MPI implementation isn't supported
# TODO: Do this automatically

# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)

# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    # `ADIOS2_jll` is available only for 64-bit platforms
    Dependency(PackageSpec(name="ADIOS2_jll"); platforms=filter(p -> nbits(p) ≠ 32, platforms)),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    # Parallel HDF5 is not available on Windows
    Dependency(PackageSpec(name="HDF5_jll"); compat="~1.14", platforms=filter(!Sys.iswindows, platforms)),
]

append!(dependencies, platform_dependencies)

# The products that we will ensure are always built.
# Don't dlopen `libopenPMD` because it might transitively require libgfortran.
products = [
    ExecutableProduct("openpmd-ls", :openpmd_ls),
    LibraryProduct("libopenPMD", :libopenPMD),
    LibraryProduct("libopenPMD.c", :libopenPMD_c),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We need C++17 which requires at least GCC 9.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"9")
