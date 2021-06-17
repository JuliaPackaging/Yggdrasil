# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "AMReX"
version = v"21.6.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/AMReX-Codes/amrex/releases/download/21.06/amrex-21.06.tar.gz", "6982c22837d7c0bc4583065d9da55e0aebcf07b54386e4b90a779391fe73fd53")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd amrex
mkdir build
cd build
if [[ "$target" == x86_64-w64-mingw32 ]]; then
    mpiopts="-DMPI_HOME=$prefix -DMPI_GUESS_LIBRARY_NAME=MSMPI -DMPI_C_LIBRARIES=msmpi64 -DMPI_CXX_LIBRARIES=msmpi64"
elif [[ "$target" == *-mingw* ]]; then
    mpiopts="-DMPI_HOME=$prefix -DMPI_GUESS_LIBRARY_NAME=MSMPI"
else
    mpiopts=
fi
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake -DCMAKE_BUILD_TYPE=Release -DAMReX_FORTRAN=OFF -DAMReX_OMP=ON -DAMReX_PARTICLES=ON -DBUILD_SHARED_LIBS=ON ${mpiopts} ..
make -j${nproc}
make -j${nproc} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# We cannot build with musl since AMReX requires the `fegetexcept` GNU API
platforms = filter(p -> libc(p) ≠ "musl", platforms)
# Apparently, macOS doesn't use different C++ string APIs
platforms = expand_cxxstring_abis(platforms; skip=Sys.isapple)

# The products that we will ensure are always built
products = [
    LibraryProduct("libamrex", :libamrex)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    # AMReX's cmake stage fails with OpenMPI on almost all architectures
    # Dependency(PackageSpec(name="OpenMPI_jll", uuid="fe0851c0-eecd-5654-98d4-656369965a5c")),
    Dependency(PackageSpec(name="MPICH_jll")),
    Dependency(PackageSpec(name="MicrosoftMPI_jll")),
]

# Build the tarballs, and possibly a `build.jl` as well.
# - GCC 4 is too old: AMReX requires C++14, and thus at least GCC 5
# - On Windows, AMReX requires C++17, and at least GCC 8 to provide the <filesystem> header.
#   How can we require this for Windows only?
# - GCC 8.1.0 suffers from an ICE, so we use GCC 9 instead
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9")
