# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "openPMD_api"
version = v"0.15.2"
openpmi_api_version = "v.0.14.5" # This is really the `dev` branch after version 0.14.5

# `v"1.6.3"` fails to build
julia_versions = [v"1.7.0", v"1.8.0", v"1.9.0"]

# Collection of sources required to complete build
sources = [
    # ArchiveSource("https://github.com/openPMD/openPMD-api/archive/refs/tags/0.13.4.tar.gz",
    #               "46c013be5cda670f21969675ce839315d4f5ada0406a6546a91ec3441402cf5e"),
    # We use a feature branch instead of a released version because the Julia bindings are not released yet
    ArchiveSource("https://github.com/eschnett/openPMD-api/archive/20cdbe774e9dd5b739f3aede0c7fc69a7dbaf431.tar.gz",
                  "1004cee967e36522b17742ef946451fb9d852a78e05950206c854ce6a5764cd9"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
]

# Bash recipe for building across all platforms
script = raw"""
# Log which MPI implementation is actually used
grep -iq MPICH $prefix/include/mpi.h && echo 'MPI: MPICH'
grep -iq MPItrampoline $prefix/include/mpi.h && echo 'MPI: MPItrampoline'
grep -iq OpenMPI $prefix/include/mpi.h && echo 'MPI: OpenMPI'

cd $WORKSPACE/srcdir
cd openPMD-api-*
mkdir build
cd build

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
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
fi

mpiopts=
if [[ "$target" == *-apple-* ]]; then
    if grep -q MPICH_NAME $prefix/include/mpi.h; then
        # MPICH's pkgconfig file "mpich.pc" lists these options:
        #     Libs:     -framework OpenCL -Wl,-flat_namespace -Wl,-commons,use_dylibs -L${libdir} -lmpi -lpmpi -lm    -lpthread
        #     Cflags:   -I${includedir}
        # cmake doesn't know how to handle the "-framework OpenCL" option
        # and wants to use "-framework" as a stand-alone option. This fails
        # gloriously, and cmake concludes that MPI is not available.
        mpiopts="-DMPI_C_ADDITIONAL_INCLUDE_DIRS='' -DMPI_C_LIBRARIES='-Wl,-flat_namespace;-Wl,-commons,use_dylibs;-lmpi;-lpmpi' -DMPI_CXX_ADDITIONAL_INCLUDE_DIRS='' -DMPI_CXX_LIBRARIES='-Wl,-flat_namespace;-Wl,-commons,use_dylibs;-lmpi;-lpmpi'"
    fi
elif [[ "$target" == x86_64-w64-mingw32 ]]; then
    # - The MSMPI Fortran bindings are missing a function; see
    #   <https://github.com/microsoft/Microsoft-MPI/issues/7>
    echo 'void __guard_check_icall_fptr(unsigned long ptr) {}' >cfg_stub.c
    gcc -c cfg_stub.c
    ar -crs libcfg_stub.a cfg_stub.o
    cp libcfg_stub.a $prefix/lib
    # - cmake's auto-detection for MPI doesn't work on Windows.
    # - The SST and Table ADIOS2 components don't build on Windows
    #   (reported in <https://github.com/ornladios/ADIOS2/issues/2705>)
    export FFLAGS="-I$prefix/src -I$prefix/include -fno-range-check"
    mpiopts="-DMPI_GUESS_LIBRARY_NAME=MSMPI -DMPI_C_LIBRARIES=msmpi64 -DMPI_CXX_LIBRARIES=msmpi64 -DMPI_Fortran_LIBRARIES='msmpifec64;msmpi64;cfg_stub' -DADIOS2_USE_SST=OFF -DADIOS2_USE_Table=OFF"
elif [[ "$target" == *-mingw* ]]; then
    mpiopts="-DMPI_GUESS_LIBRARY_NAME=MSMPI -DADIOS2_USE_SST=OFF -DADIOS2_USE_Table=OFF"
fi

testopts=
if [[ "$target" == *-apple-* ]]; then
    testopts="-DBUILD_TESTING=OFF"
fi

cmake \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_FIND_ROOT_PATH=$prefix \
    -DJulia_PREFIX=$prefix \
    -DopenPMD_USE_Julia=ON \
    -DopenPMD_USE_MPI=ON \
    -DMPI_HOME=$prefix \
    ${mpiopts} \
    ${testopts} \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    ..

cmake --build . --config RelWithDebInfo --parallel $nproc
cmake --build . --config RelWithDebInfo --parallel $nproc --target install
install_license ../COPYING*
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# platforms = supported_platforms()
# Use only platforms where libcxxwrap_julia is supported.
include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libopenPMD", :libopenPMD),
    LibraryProduct("libopenPMD.jl", :libopenPMD_jl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="libjulia_jll")),
    # `ADIOS2_jll` is available only for 64-bit platforms
    Dependency(PackageSpec(name="ADIOS2_jll"); platforms=filter(p -> nbits(p) ≠ 32, platforms)),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    # We would need a parallel version of HDF5
    # Dependency(PackageSpec(name="HDF5_jll")),
    Dependency(PackageSpec(name="libcxxwrap_julia_jll")),
]

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# Avoid platforms where the MPI implementation isn't supported
# TODO: Do this automatically

# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)

# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

append!(dependencies, platform_dependencies)

# See <https://github.com/JuliaPackaging/Yggdrasil/blob/master/Q/Qt5Base/build_tarballs.jl> for building on macOS 10.14

# Build the tarballs, and possibly a `build.jl` as well.
# We need C++14, which requires at least GCC 5.
# GCC 5 reports incompatible signatures for `posix_memalign` on linux/musl, fixed on GCC 6
# GCC 5 has a bug regarding `std::to_string` on freebsd, fixed on GCC 6
# macOS encounters an ICE in GCC 6; switching to GCC 7 instead
# Let's use GCC 8 to have libgfortran5 ABI and make auditor happy when looking for libgfortran: #5028
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.7", preferred_gcc_version=v"8")
