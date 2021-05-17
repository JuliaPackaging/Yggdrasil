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
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/shlwapi.patch
mkdir build
cd build
if [[ "$target" == *-apple-* ]]; then
    # Set up a wrapper script for the assembler. GCC's assembler
    # output isn't accepted by the LLVM assembler.
    as=$(which as)
    mv "$as" "$as.old"
    export AS="$as.old"
    ln -s "$WORKSPACE/srcdir/scripts/as.llvm" "$as"
fi
mpiopts=
winopts=
if [[ "$target" == x86_64-w64-mingw32 ]]; then
    # cmake's auto-detection doesn't work on Windows.
    # The SST and Table ADIOS2 components don't build on Windows
    # (reported in <https://github.com/ornladios/ADIOS2/issues/2705>)
    mpiopts="-DMPI_HOME=$prefix -DMPI_GUESS_LIBRARY_NAME=MSMPI -DMPI_C_LIBRARIES=msmpi64 -DMPI_CXX_LIBRARIES=msmpi64"
    winopts="-DADIOS2_USE_SST=OFF -DADIOS2_USE_Table=OFF"
elif [[ "$target" == *-mingw* ]]; then
    mpiopts="-DMPI_HOME=$prefix -DMPI_GUESS_LIBRARY_NAME=MSMPI"
    winopts="-DADIOS2_USE_SST=OFF -DADIOS2_USE_Table=OFF"
fi
# We disable Fortran because this would require building many more
# versions of the library
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake -DCMAKE_BUILD_TYPE=Release -DADIOS2_USE_Fortran=OFF -DADIOS2_BUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF ${mpiopts} ${winopts} ..
make -j${nproc}
make -j${nproc} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),

    # These platforms fail:

    # [22:03:24] /workspace/srcdir/ADIOS2-2.7.1/source/adios2/engine/ssc/SscReader.cpp:420:71: error: narrowing conversion of ‘18446744073709551613ull’ from ‘long long unsigned int’ to ‘unsigned int’ inside { } [-Wnarrowing]
    # [22:03:24]                  m_IO.DefineVariable<T>(b.name, {adios2::LocalValueDim});       \
    # (32-bit architectures are officially not supported.)
    #FAIL Platform("armv7l", "linux"; libc="glibc"),
    #FAIL Platform("i686", "linux"; libc="glibc"),
    #TODO Platform("i686", "linux"; libc="musl"),
    #TODO Platform("i686", "windows"),

    # [22:40:43] /workspace/srcdir/ADIOS2-2.7.1/source/adios2/toolkit/profiling/taustubs/tautimer.cpp:208:31: error: ‘__NR_gettid’ was not declared in this scope
    # [22:40:43]      mytid = (uint64_t)syscall(__NR_gettid);
    # (Likely the respective syscall does not exist on FreeBSD;
    # reported as <https://github.com/ornladios/ADIOS2/issues/2705>.)
    #FAIL Platform("x86_64", "freebsd"),
]
# Apparently, macOS doesn't use different C++ string APIs
platforms = expand_cxxstring_abis(platforms; skip=Sys.isapple)

# The products that we will ensure are always built
products = [
    LibraryProduct("libadios2_c_mpi", :libadios2_c_mpi),
    LibraryProduct("libadios2_c", :libadios2_c),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Blosc_jll")),
    Dependency(PackageSpec(name="Bzip2_jll")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="MPICH_jll")),
    Dependency(PackageSpec(name="MicrosoftMPI_jll")),
    Dependency(PackageSpec(name="Python_jll")),
    Dependency(PackageSpec(name="ZeroMQ_jll")),
    Dependency(PackageSpec(name="libpng_jll")),
    Dependency(PackageSpec(name="zfp_jll")),
    # (HDF5: cannot do; we would need HDF5 with MPI support)
]

# Build the tarballs, and possibly a `build.jl` as well.
# GCC 4 is too old for Windows; it doesn't have <regex.h>
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5")
