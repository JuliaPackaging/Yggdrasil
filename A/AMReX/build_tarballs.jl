# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "AMReX"
version = v"21.4.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/AMReX-Codes/amrex/releases/download/21.04/amrex-21.04.tar.gz", "1c610e4b0800b16f7f1da74193ff11af0abfb12198b36a7e565a6a7f793087fa")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd amrex
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DAMReX_FORTRAN=OFF -DAMReX_FORTRAN_INTERFACES=OFF -DAMReX_OMP=ON -DAMReX_PARTICLES=ON -DBUILD_SHARED_LIBS=ON -DXSDK_ENABLE_Fortran=OFF ..
make -j$(nproc)
make -j$(nproc) install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("aarch64", "linux"; libc="glibc"),
    # Platform("aarch64", "linux"; libc="musl"), # `fegetexcept` missing 
    Platform("armv7l", "linux"; libc="glibc"),
    # Platform("armv7l", "linux"; libc="musl"), # `fegetexcept` missing 
    Platform("i686", "linux"; libc = "glibc"),
    # Platform("i686", "linux"; libc="musl"), # `fegetexcept` missing 
    # Platform("i686", "windows"),            # MPICH not available
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("x86_64", "freebsd"),
    Platform("x86_64", "linux"; libc = "glibc"),
    # Platform("x86_64", "linux"; libc="musl"), # `fegetexcept` missing 
    # Platform("x86_64", "macos"),   # no OpenMP support
    # Platform("x86_64", "windows"), # MPICH not available
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libamrex", :libamrex)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    # cmake fails with OpenMPI on almost all architectures; it claims OpenMPI does not support Fortran
    # Dependency(PackageSpec(name="OpenMPI_jll", uuid="fe0851c0-eecd-5654-98d4-656369965a5c")),
    Dependency(PackageSpec(name="MPICH_jll")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0")
