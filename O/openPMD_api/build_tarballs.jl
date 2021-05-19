# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "openPMD_api"
version = v"0.13.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/openPMD/openPMD-api/archive/refs/tags/0.13.4.tar.gz",
                  "46c013be5cda670f21969675ce839315d4f5ada0406a6546a91ec3441402cf5e"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd openPMD-api-0.13.4
mkdir build
cd build
if [[ "$target" == *-apple-* ]]; then
    # Set up a wrapper script for the assembler. GCC's assembly
    # output isn't accepted by the LLVM assembler.
    as=$(which as)
    mv "$as" "$as.old"
    export AS="$as.old"
    ln -s "$WORKSPACE/srcdir/scripts/as.llvm" "$as"
fi
mpiopts=
if [[ "$target" == x86_64-w64-mingw32 ]]; then
    mpiopts="-DMPI_HOME=$prefix -DMPI_GUESS_LIBRARY_NAME=MSMPI -DMPI_C_LIBRARIES=msmpi64 -DMPI_CXX_LIBRARIES=msmpi64"
elif [[ "$target" == *-mingw* ]]; then
    mpiopts="-DMPI_HOME=$prefix -DMPI_GUESS_LIBRARY_NAME=MSMPI"
fi
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake -DCMAKE_BUILD_TYPE=Release ${mpiopts} ..
make -j${nproc}
make -j${nproc} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("i686", "windows"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),

    # linux/musl doesn't work because `posix_memalign` is defined with
    # two incompatible signatures in the GCC 5 header files
    Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl"),

    # [14:13:53] /workspace/srcdir/openPMD-api-0.13.4/include/openPMD/Datatype.hpp:771:13: error: ‘to_string’ is not a member of ‘std’
    # [14:13:53]              std::to_string( static_cast< int >( dt ) ) );
    Platform("x86_64", "freebsd"),
]
# Apparently, macOS doesn't use different C++ string APIs
platforms = expand_cxxstring_abis(platforms; skip=Sys.isapple)

# The products that we will ensure are always built
products = [
    LibraryProduct("libopenPMD", :libopenPMD),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="ADIOS2_jll")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    # We would need a parallel version of HDF5
    # Dependency(PackageSpec(name="HDF5_jll")),
    Dependency(PackageSpec(name="MPICH_jll")),
    Dependency(PackageSpec(name="MicrosoftMPI_jll")),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We need C++14, which requires at least GCC 5.
# GCC 5 has a bug regarding `std::to_string` on freebsd, fixed on GCC 6
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"6")
