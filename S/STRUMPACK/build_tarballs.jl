# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "STRUMPACK"
version = v"8.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pghysels/STRUMPACK.git",
              "9a45f304f21e1d9c44c6fa50ac2f044ab15cf342")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/STRUMPACK

# FortranCInterface_VERIFY fails on Apple because the verification link step
# pulls in an incompatible libgcc_ext from the cross toolchain. The generated
# header is still created by FortranCInterface_HEADER, so the verify step can be
# skipped safely for this package.
sed -i 's/FortranCInterface_VERIFY(CXX)/if(NOT APPLE)\n  FortranCInterface_VERIFY(CXX)\nendif()/' CMakeLists.txt

# Windows DLLs are installed as RUNTIME products, so make sure the shared
# library lands in ${bindir} where BinaryBuilder looks for it.
sed -i 's/LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}/LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}\n  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}/' CMakeLists.txt

# Fix FindMETIS.cmake: when IDXTYPEWIDTH is not #define'd in metis.h
# (METIS_jll passes it as a compiler flag), metis_idxwidth is empty and
# the unquoted ${metis_idxwidth} causes a "REGEX REPLACE needs at least 6
# arguments" error. Wrap the problematic block in an if() guard.
sed -i 's/string( REGEX REPLACE ${idxwidth_pattern}/if(metis_idxwidth)\n  string( REGEX REPLACE ${idxwidth_pattern}/' cmake/Modules/FindMETIS.cmake
sed -i 's/METIS_IDXWIDTH_STRING ${metis_idxwidth} )/METIS_IDXWIDTH_STRING "${metis_idxwidth}" )\n  endif()/' cmake/Modules/FindMETIS.cmake

# On Darwin, mixing clang++ link with gfortran runtime can pull in
# libgcc_ext.10.5.dylib that ld64.lld rejects. Force GCC/G++ in CMake
# directly (toolchain files can ignore CC/CXX environment variables).
cmake_compiler_flags=""
if [[ "${target}" == *-apple-* ]]; then
    cmake_compiler_flags="-DCMAKE_C_COMPILER=${target}-gcc -DCMAKE_CXX_COMPILER=${target}-g++"
fi

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    ${cmake_compiler_flags} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DSTRUMPACK_USE_MPI=OFF \
    -DSTRUMPACK_USE_OPENMP=ON \
    -DSTRUMPACK_USE_CUDA=OFF \
    -DSTRUMPACK_USE_HIP=OFF \
    -DSTRUMPACK_USE_SYCL=OFF \
    -DTPL_BLAS_LIBRARIES="${libdir}/libopenblas.${dlext}" \
    -DTPL_LAPACK_LIBRARIES="${libdir}/libopenblas.${dlext}" \
    -DTPL_ENABLE_SLATE=OFF \
    -DTPL_ENABLE_PARMETIS=OFF \
    -DTPL_ENABLE_SCOTCH=OFF \
    -DTPL_ENABLE_PTSCOTCH=OFF \
    -DTPL_ENABLE_BPACK=OFF \
    -DTPL_ENABLE_COMBBLAS=OFF \
    -DTPL_ENABLE_ZFP=OFF \
    -DTPL_ENABLE_SZ3=OFF \
    -DTPL_ENABLE_MAGMA=OFF \
    -DTPL_ENABLE_KBLAS=OFF \
    -DTPL_ENABLE_PAPI=OFF \
    -DTPL_ENABLE_MATLAB=OFF \
    -Dmetis_PREFIX=${prefix} \
    -DSTRUMPACK_COUNT_FLOPS=OFF \
    -DSTRUMPACK_TASK_TIMERS=OFF \
    -DSTRUMPACK_MESSAGE_COUNTER=OFF \
    -DSTRUMPACK_BUILD_TESTS=OFF

cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# NOTE: 32-bit platforms are excluded because STRUMPACK defines separate
# overloads for `unsigned int` and `std::size_t` which are the same type
# on 32-bit, causing redefinition errors (upstream bug).
platforms = filter(p -> nbits(p) == 64, supported_platforms())
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libstrumpack", :libstrumpack)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("METIS_jll"; compat="5.1.3"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6",
    preferred_gcc_version=v"8")
