# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "AMReX"
version_string = "23.02"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/AMReX-Codes/amrex/releases/download/$(version_string)/amrex-$(version_string).tar.gz",
                  "f443c5eb4b89f4a74bf0e1b8a5943da18ab81cdc76aff12e8282ca43ffd06412"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd amrex
mkdir build
cd build
if [[ "$target" == *-apple-* ]]; then
    # Apple's Clang does not support OpenMP
    omp_opts="-DAMReX_OMP=OFF"
else
    omp_opts="-DAMReX_OMP=ON"
fi
if [[ "$target" == *-apple-* ]]; then
    if grep -q MPICH_NAME $prefix/include/mpi.h; then
        # MPICH's pkgconfig file "mpich.pc" lists these options:
        #     Libs:     -framework OpenCL -Wl,-flat_namespace -Wl,-commons,use_dylibs -L${libdir} -lmpi -lpmpi -lm    -lpthread
        #     Cflags:   -I${includedir}
        # cmake doesn't know how to handle the "-framework OpenCL" option
        # and wants to use "-framework" as a stand-alone option. This fails,
        # and cmake concludes that MPI is not available.
        mpiopts="-DMPI_C_ADDITIONAL_INCLUDE_DIRS='' -DMPI_C_LIBRARIES='-Wl,-flat_namespace;-Wl,-commons,use_dylibs;-lmpi;-lpmpi' -DMPI_CXX_ADDITIONAL_INCLUDE_DIRS='' -DMPI_CXX_LIBRARIES='-Wl,-flat_namespace;-Wl,-commons,use_dylibs;-lmpi;-lpmpi'"
    fi
elif [[ "$target" == x86_64-w64-mingw32 ]]; then
    mpiopts="-DMPI_HOME=$prefix -DMPI_GUESS_LIBRARY_NAME=MSMPI -DMPI_C_LIBRARIES=msmpi64 -DMPI_CXX_LIBRARIES=msmpi64"
elif [[ "$target" == *-mingw* ]]; then
    mpiopts="-DMPI_HOME=$prefix -DMPI_GUESS_LIBRARY_NAME=MSMPI"
else
    mpiopts=
fi
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DAMReX_FORTRAN=ON \
    -DAMReX_MPI=ON \
    -DAMReX_PARTICLES=ON \
    -DBUILD_SHARED_LIBS=ON \
    ${ompopts} \
    ${mpiopts} \
    ..
cmake --build . --config RelWithDebInfo --parallel $nproc
cmake --build . --config RelWithDebInfo --parallel $nproc --target install
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# We cannot build with musl since AMReX requires the `fegetexcept` GNU API
platforms = filter(p -> libc(p) ≠ "musl", platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libamrex", :libamrex)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

platforms, platform_dependencies = MPI.augment_platforms(platforms)
# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && (Sys.iswindows(p) || libc(p) == "musl")), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
# - GCC 4 is too old: AMReX requires C++14, and thus at least GCC 5
# - On Windows, AMReX requires C++17, and at least GCC 8 to provide the <filesystem> header.
#   How can we require this for Windows only?
# - GCC 8.1.0 suffers from an ICE, so we use GCC 9 instead
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version = v"9")
