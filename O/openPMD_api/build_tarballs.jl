# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

julia_version = v"1.6.0"        # Must probably be the same as in libcxxwrap_julia

name = "openPMD_api"
version = v"0.14.2"

# Collection of sources required to complete build
sources = [
    # ArchiveSource("https://github.com/openPMD/openPMD-api/archive/refs/tags/0.13.4.tar.gz",
    #               "46c013be5cda670f21969675ce839315d4f5ada0406a6546a91ec3441402cf5e"),
    # We temporarily use a feature branch instead of a released
    # version because the Julia bindings are not release yet
    ArchiveSource("https://github.com/eschnett/openPMD-api/archive/0df99cc11cfe7555e6d099d62b4016412b650f34.tar.gz",
                  "421538de3a8cba2171a1f2deb5774a340896aa4579e77178a9df27b634fb980d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd openPMD-api-*
mkdir build
cd build
mpiopts=
if [[ "$target" == *-apple-* ]]; then
    # MPICH's pkgconfig file "mpich.pc" lists these options:
    #     Libs:     -framework OpenCL -Wl,-flat_namespace -Wl,-commons,use_dylibs -L${libdir} -lmpi -lpmpi -lm    -lpthread
    #     Cflags:   -I${includedir}
    # cmake doesn't know how to handle the "-framework OpenCL" option
    # and wants to use "-framework" as a stand-alone option. This fails,
    # and cmake concludes that MPI is not available.
    mpiopts="-DMPI_C_ADDITIONAL_INCLUDE_DIRS='' -DMPI_C_LIBRARIES='-Wl,-flat_namespace;-Wl,-commons,use_dylibs;-lmpi;-lpmpi' -DMPI_CXX_ADDITIONAL_INCLUDE_DIRS='' -DMPI_CXX_LIBRARIES='-Wl,-flat_namespace;-Wl,-commons,use_dylibs;-lmpi;-lpmpi'"
elif [[ "$target" == x86_64-w64-mingw32 ]]; then
    mpiopts="-DMPI_GUESS_LIBRARY_NAME=MSMPI -DMPI_C_LIBRARIES=msmpi64 -DMPI_CXX_LIBRARIES=msmpi64"
elif [[ "$target" == *-mingw* ]]; then
    mpiopts="-DMPI_GUESS_LIBRARY_NAME=MSMPI"
fi
testopts=
if [[ "$target" == *-apple-* ]]; then
    testopts="-DBUILD_TESTING=OFF"
fi
# -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake
cmake \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_FIND_ROOT_PATH=$prefix \
    -DJulia_PREFIX=$prefix \
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

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# platforms = supported_platforms()
# Use only platforms where libcxxwrap_julia is supported.
include("../../L/libjulia/common.jl")
platforms = libjulia_platforms(julia_version)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libopenPMD", :libopenPMD),
    LibraryProduct("libopenPMD_jl", :libopenPMD_jl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="libjulia_jll", version=julia_version)),
    Dependency(PackageSpec(name="ADIOS2_jll")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    # We would need a parallel version of HDF5
    # Dependency(PackageSpec(name="HDF5_jll")),
    Dependency(PackageSpec(name="MPICH_jll")),
    Dependency(PackageSpec(name="MicrosoftMPI_jll")),
    Dependency(PackageSpec(name="libcxxwrap_julia_jll")),
]

# See <https://github.com/JuliaPackaging/Yggdrasil/blob/master/Q/Qt5Base/build_tarballs.jl> for building on macOS 10.14

# Build the tarballs, and possibly a `build.jl` as well.
# We need C++14, which requires at least GCC 5.
# GCC 5 reports incompatible signatures for `posix_memalign` on linux/musl, fixed on GCC 6
# GCC 5 has a bug regarding `std::to_string` on freebsd, fixed on GCC 6
# macos encounters an ICE in GCC 6; switching to GCC 7 instead
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version = v"7")
