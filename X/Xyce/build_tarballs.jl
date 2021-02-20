# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Xyce"
version = v"7.2.0"

# Collection of sources required to complete build
sources = [
            GitSource("https://github.com/Xyce/Xyce.git", "a61faef4bfb2f36f1aa7cc44264bbbb66fbaac11")
            GitSource("https://github.com/trilinos/Trilinos.git", "512a9e81183c609ab16366a9b09d70d37c6af8d4")
          ]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir trilbuild
cd trilbuild
SRCDIR="/workspace/srcdir/Trilinos"
FLAGS="-O3 -fPIC"
cmake -G "Unix Makefiles" -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ \
-DCMAKE_Fortran_COMPILER=gfortran -DCMAKE_CXX_FLAGS="$FLAGS" -DCMAKE_C_FLAGS="$FLAGS" \
-DCMAKE_Fortran_FLAGS="$FLAGS" -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX="$prefix" \
-DCMAKE_MAKE_PROGRAM="make" -DTrilinos_ENABLE_NOX=ON -DNOX_ENABLE_LOCA=ON \
-DTrilinos_ENABLE_EpetraExt=ON   -DEpetraExt_BUILD_BTF=ON   -DEpetraExt_BUILD_EXPERIMENTAL=ON \
-DEpetraExt_BUILD_GRAPH_REORDERINGS=ON -DTrilinos_ENABLE_TrilinosCouplings=ON -DTrilinos_ENABLE_Ifpack=ON \
-DTrilinos_ENABLE_Isorropia=ON -DTrilinos_ENABLE_AztecOO=ON -DTrilinos_ENABLE_Belos=ON \
-DTrilinos_ENABLE_Teuchos=ON -DTeuchos_ENABLE_COMPLEX=ON -DTrilinos_ENABLE_Amesos=ON \
-DAmesos_ENABLE_KLU=ON -DTrilinos_ENABLE_Sacado=ON -DTrilinos_ENABLE_Kokkos=OFF \
-DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF -DTrilinos_ENABLE_CXX11=ON -DTPL_ENABLE_AMD=ON \
-DAMD_LIBRARY_DIRS="/${libdir}" -DAMD_LIBRARY_NAMES="libsuitesparseconfig.${dlext};libamd.${dlext};libklu.${dlext};libcolamd.${dlext};libbtf.${dlext}" \
-DAMD_INCLUDE_DIRS="${prefix}/include" \
-DTPL_ENABLE_UMFPACK=ON \
-DUMFPACK_LIBRARY_DIRS="/${libdir}" \
-DAMD_LIBRARY_NAMES="libumfpack.${dlext}" \
-DTPL_UMFPACK_INCLUDE_DIRS="${prefix}/include" \
-DTPL_ENABLE_BLAS=ON -DTPL_ENABLE_LAPACK=ON \
-DBLAS_LIBRARY_DIRS="${prefix}/lib" -DBLAS_LIBRARY_NAMES="libopenblas.${dlext}" \
-DLAPACK_LIBRARY_DIRS="${prefix}/lib" -DLAPACK_LIBRARY_NAMES="libopenblas.${dlext}" \
-DCMAKE_BUILD_TYPE=Release $SRCDIR
make -j${nprocs}
make install
cd ..
cd Xyce
autoreconf -fiv
cd ..
mkdir build
cd build
/workspace/srcdir/Xyce/./configure --enable-shared --disable-mpi --disable-fft LDFLAGS="-L${libdir} -lopenblas" CPPFLAGS="-I/$prefix/include"
make -j${nprocs}
make install
"""

platforms = [
            Linux(:x86_64, libc=:glibc)
            ]



products = [
            LibraryProduct("libNeuronModels", :libNeuronModels),
            ]

dependencies = [
                Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
                Dependency(PackageSpec(name="SuiteSparse_jll", uuid="bea87d4a-7f5b-5778-9afe-8cc45184846c"))
                Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
                #Dependency(PackageSpec(name="FFTW_jll"))
                #Dependency(PackageSpec(name="Trilinos_jll", uuid="b6fd3212-6f87-5999-b9ea-021e9cd21b17"))
            ]


# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0")

# Wizard suggests to add `cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release`
# to the raw file when Trilinos_jll is added as a `Dependency`
