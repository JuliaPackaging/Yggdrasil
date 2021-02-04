# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Trilinos"
version = v"12.12.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/trilinos/Trilinos.git", "512a9e81183c609ab16366a9b09d70d37c6af8d4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir build; cd build
cmake /workspace/srcdir/Trilinos -G "Unix Makefiles" -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DCMAKE_Fortran_COMPILER=gfortran -DCMAKE_CXX_FLAGS="$FLAGS" -DCMAKE_C_FLAGS="$FLAGS" -DCMAKE_Fortran_FLAGS="$FLAGS" -DCMAKE_MAKE_PROGRAM="make" -DTrilinos_ENABLE_NOX=ON -DNOX_ENABLE_LOCA=ON -DTrilinos_ENABLE_EpetraExt=ON -DEpetraExt_BUILD_BTF=ON -DEpetraExt_BUILD_EXPERIMENTAL=ON -DEpetraExt_BUILD_GRAPH_REORDERINGS=ON -DTrilinos_ENABLE_TrilinosCouplings=ON -DTrilinos_ENABLE_Ifpack=ON -DTrilinos_ENABLE_Isorropia=ON -DTrilinos_ENABLE_AztecOO=ON -DTrilinos_ENABLE_Belos=ON -DTrilinos_ENABLE_Teuchos=ON -DTeuchos_ENABLE_COMPLEX=ON -DTrilinos_ENABLE_Amesos=ON -DAmesos_ENABLE_KLU=ON -DTrilinos_ENABLE_Sacado=ON -DTrilinos_ENABLE_Kokkos=OFF -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF -DTrilinos_ENABLE_CPACK_PACKAGING=ON -DTrilinos_ENABLE_CXX11=ON -DTPL_ENABLE_AMD=ON -DAMD_LIBRARY_DIRS="/$prefix/lib" -DTPL_AMD_INCLUDE_DIRS="/$prefix/include/SuiteSparseQR_C" -DTPL_BLAS_LIBRARIES='/${prefix}/lib/libopenblas.so;${prefix}/lib/libopenblas64_.so;${prefix}/lib/libopenblas.so.0;${prefix}/lib/libopenblas64_.so.0;${prefix}/lib/libopenblas.0.3.9.so' -DTPL_LAPACK_LIBRARIES="/$prefix/bin/libopenblas" -DTPL_BLAS_INCLUDE_DIRS='/${prefix}/include/cblas;/${prefix}/include/f77blas' -DTPL_LAPACK_INCLUDE_DIRS="/$prefix/include/lapack" -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
cd ..; cd Trilinos/packages/zoltan
autoreconf -fiv
cd ../../..
cd build
/workspace/srcdir/Trilinos/packages/zoltan/./configure --disable-mpi --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("armv7l", "linux"; libc="glibc", call_abi="eabihf"),
    Platform("powerpc64le", "linux"; libc="glibc"),
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("mpirun", :mpirun)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
    Dependency(PackageSpec(name="SuiteSparse_jll", uuid="bea87d4a-7f5b-5778-9afe-8cc45184846c"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
