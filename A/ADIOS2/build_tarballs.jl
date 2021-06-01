# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ADIOS2"
version = v"2.7.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/ornladios/ADIOS2/archive/refs/tags/v2.7.1.tar.gz", "c8e237fd51f49d8a62a0660db12b72ea5067512aa7970f3fcf80b70e3f87ca3e"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd ADIOS2-2.7.1
# See <https://github.com/ornladios/ADIOS2/issues/2705>
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/gettid.patch
# PR <https://github.com/ornladios/ADIOS2/pull/2712>
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/ndims.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/shlwapi.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/sockaddr_in.patch
mkdir build
cd build
if [[ "$target" == *-apple-* ]]; then
    # Set up a wrapper script for the assembler. GCC's assembly output
    # isn't accepted by the LLVM assembler.
    as=$(which as)
    mv "$as" "$as.old"
    export AS="$as.old"
    ln -s "$WORKSPACE/srcdir/scripts/as.llvm" "$as"
fi
archopts=
if [[ "$target" == x86_64-w64-mingw32 ]]; then
    # - The MSMPI Fortran bindings are missing a function; see
    #   <https://github.com/microsoft/Microsoft-MPI/issues/7>
    echo 'void __guard_check_icall_fptr(unsigned long ptr) {}' >cfg_stub.c
    gcc -c cfg_stub.c
    ar -crs libcfg_stub.a cfg_stub.o
    cp libcfg_stub.a $prefix/lib
    # cp $prefix/src/mpi.f90 $prefix/include
    # - cmake's auto-detection for MPI doesn't work on Windows.
    # - The SST and Table ADIOS2 components don't build on Windows
    #   (reported in <https://github.com/ornladios/ADIOS2/issues/2705>)
    export FFLAGS="-I$prefix/src -I$prefix/include -fno-range-check"
    # -DMPI_Fortran_COMPILER_FLAGS='-fno-range-check;-I$prefix/src;-I$prefix/include'
    # -DMPI_Fortran_ADDITIONAL_INCLUDE_DIRS='$prefix/src;$prefix/include'
    archopts="-DMPI_HOME=$prefix -DMPI_GUESS_LIBRARY_NAME=MSMPI -DMPI_C_LIBRARIES=msmpi64 -DMPI_CXX_LIBRARIES=msmpi64 -DMPI_Fortran_LIBRARIES='msmpifec64;msmpi64;cfg_stub' -DADIOS2_USE_SST=OFF -DADIOS2_USE_Table=OFF"
elif [[ "$target" == *-mingw* ]]; then
    archopts="-DMPI_HOME=$prefix -DMPI_GUESS_LIBRARY_NAME=MSMPI -DADIOS2_USE_SST=OFF -DADIOS2_USE_Table=OFF"
fi
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake -DCMAKE_BUILD_TYPE=Release -DADIOS2_BUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF ${archopts} ..
make -j${nproc}
make -j${nproc} install
install_license ../Copyright.txt ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
#TODO platforms = [
#TODO     Platform("aarch64", "linux"; libc="glibc"),
#TODO     Platform("aarch64", "linux"; libc="musl"),
#TODO     Platform("powerpc64le", "linux"; libc="glibc"),
#TODO     Platform("x86_64", "freebsd"),
#TODO     Platform("x86_64", "linux"; libc="glibc"),
#TODO     Platform("x86_64", "linux"; libc="musl"),
#TODO     Platform("x86_64", "macos"),
#TODO     Platform("x86_64", "windows"),
#TODO 
#TODO     # These platforms fail:
#TODO 
#TODO     # [22:03:24] /workspace/srcdir/ADIOS2-2.7.1/source/adios2/engine/ssc/SscReader.cpp:420:71: error: narrowing conversion of ‘18446744073709551613ull’ from ‘long long unsigned int’ to ‘unsigned int’ inside { } [-Wnarrowing]
#TODO     # [22:03:24]                  m_IO.DefineVariable<T>(b.name, {adios2::LocalValueDim});       \
#TODO     # (32-bit architectures are not supported; see
#TODO     # <https://github.com/ornladios/ADIOS2/issues/2704>.)
#TODO     #FAIL Platform("armv7l", "linux"; libc="glibc"),
#TODO     #FAIL Platform("i686", "linux"; libc="glibc"),
#TODO     #TODO Platform("i686", "linux"; libc="musl"),
#TODO     #TODO Platform("i686", "windows"),
#TODO ]
platforms = supported_platforms()
# 32-bit architectures are not supported; see
# <https://github.com/ornladios/ADIOS2/issues/2704>
platforms = filter(p -> nbits(p) ≠ 32, platforms)
# Apparently, macOS doesn't use different C++ string APIs
platforms = expand_cxxstring_abis(platforms; skip=Sys.isapple)
# TODO: Windows doesn't build with libcxx="cxx03"
platforms = expand_gfortran_versions(platforms)
# x86_64-apple-darwin-libgfortran3 encounters an ICE in GCC
platforms = filter(p -> !(Sys.isapple(p) && libgfortran_version(p) == v"3"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libadios2_c", :libadios2_c),
    LibraryProduct("libadios2_c_mpi", :libadios2_c_mpi),
    LibraryProduct("libadios2_core", :libadios2_core),
    LibraryProduct("libadios2_core_mpi", :libadios2_core_mpi),
    LibraryProduct("libadios2_cxx11", :libadios2_cxx11),
    LibraryProduct("libadios2_cxx11_mpi", :libadios2_cxx11_mpi),
    LibraryProduct("libadios2_fortran", :libadios2_fortran),
    LibraryProduct("libadios2_fortran_mpi", :libadios2_fortran_mpi),
    LibraryProduct("libadios2_taustubs", :libadios2_taustubs),

    # Missing on Windows:
    # LibraryProduct("libadios2_atl", :libadios2_atl),
    # LibraryProduct("libadios2_dill", :libadios2_dill),
    # LibraryProduct("libadios2_evpath", :libadios2_evpath),
    # LibraryProduct("libadios2_ffs", :libadios2_ffs),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Blosc_jll")),
    # We don't want to use Bzip2 because this would lock us into Julia ≥1.6
    # Dependency(PackageSpec(name="Bzip2_jll")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="MPICH_jll")),
    Dependency(PackageSpec(name="MicrosoftMPI_jll")),
    Dependency(PackageSpec(name="ZeroMQ_jll")),
    Dependency(PackageSpec(name="libpng_jll")),
    Dependency(PackageSpec(name="zfp_jll")),
    # We cannot use HDF5 because we need a HDF5 configuration with MPI support
    # Dependency(PackageSpec(name="HDF5_jll")),
]

# Build the tarballs, and possibly a `build.jl` as well.
# GCC 4 is too old for Windows; it doesn't have <regex.h>
# GCC 5 is too old for FreeBSD; it doesn't have `std::to_string`
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
