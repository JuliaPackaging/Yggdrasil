# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Xyce"
version = v"7.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/westes/flex.git", "d69a58075169410324fe49666f6641ba6a9d1f91"),
    GitSource("https://github.com/Xyce/Xyce.git", "a61faef4bfb2f36f1aa7cc44264bbbb66fbaac11"),
    GitSource("https://github.com/trilinos/Trilinos.git", "512a9e81183c609ab16366a9b09d70d37c6af8d4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd flex
apk add texinfo
apk add help2man
./autogen.sh
./configure --prefix=${prefix}
make -j${nprocs}
make install
cd ..
mkdir trilbuild
cd trilbuild
SRCDIR="/workspace/srcdir/Trilinos"
FLAGS="-O3 -fPIC"
cmake -G "Unix Makefiles" -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DCMAKE_Fortran_COMPILER=gfortran -DCMAKE_CXX_FLAGS="$FLAGS" -DCMAKE_C_FLAGS="$FLAGS" -DCMAKE_Fortran_FLAGS="$FLAGS" -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX="$prefix" -DCMAKE_MAKE_PROGRAM="make" -DTrilinos_ENABLE_NOX=ON -DNOX_ENABLE_LOCA=ON -DTrilinos_ENABLE_EpetraExt=ON   -DEpetraExt_BUILD_BTF=ON   -DEpetraExt_BUILD_EXPERIMENTAL=ON -DEpetraExt_BUILD_GRAPH_REORDERINGS=ON -DTrilinos_ENABLE_TrilinosCouplings=ON -DTrilinos_ENABLE_Ifpack=ON -DTrilinos_ENABLE_Isorropia=ON -DTrilinos_ENABLE_AztecOO=ON -DTrilinos_ENABLE_Belos=ON -DTrilinos_ENABLE_Teuchos=ON -DTeuchos_ENABLE_COMPLEX=ON -DTrilinos_ENABLE_Amesos=ON -DAmesos_ENABLE_KLU=ON -DTrilinos_ENABLE_Sacado=ON -DTrilinos_ENABLE_Kokkos=OFF -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF -DTrilinos_ENABLE_CXX11=ON -DTPL_ENABLE_AMD=ON -DAMD_LIBRARY_DIRS="/${libdir}" -DAMD_LIBRARY_NAMES="libsuitesparseconfig.${dlext};libamd.${dlext};libklu.${dlext};libcolamd.${dlext};libbtf.${dlext}" -DAMD_INCLUDE_DIRS="${prefix}/include" -DTPL_ENABLE_UMFPACK=ON -DUMFPACK_LIBRARY_DIRS="/${libdir}" -DAMD_LIBRARY_NAMES="libumfpack.${dlext}" -DTPL_UMFPACK_INCLUDE_DIRS="${prefix}/include" -DTPL_ENABLE_BLAS=ON -DTPL_ENABLE_LAPACK=ON -DBLAS_LIBRARY_DIRS="${prefix}/lib" -DBLAS_LIBRARY_NAMES="libopenblas.${dlext}" -DLAPACK_LIBRARY_DIRS="${prefix}/lib" -DLAPACK_LIBRARY_NAMES="libopenblas.${dlext}" -DCMAKE_BUILD_TYPE=Release $SRCDIR
make -j${nprocs}
make install
cd ..
cd Xyce
./bootstrap
cd ..
mkdir buildx
cd buildx
/workspace/srcdir/Xyce/./configure --enable-shared --disable-mpi --prefix=${prefix} LDFLAGS="-L${libdir} -lopenblas" CPPFLAGS="-I/$prefix/include"
cd ..
cd /workspace/destdir/
mkdir x86_64-linux-gnu
cd x86_64-linux-gnu
mkdir lib
mkdir lib64
cd /opt/x86_64-linux-gnu/x86_64-linux-gnu/lib64
cp libquadmath.a /workspace/destdir/x86_64-linux-gnu/lib64
cp libquadmath.so /workspace/destdir/x86_64-linux-gnu/lib64
cp libquadmath.la /workspace/destdir/x86_64-linux-gnu/lib64
cp libquadmath.so.0.0.0 /workspace/destdir/x86_64-linux-gnu/lib64
cp libquadmath.so.0 /workspace/destdir/x86_64-linux-gnu/lib64
cd /workspace/srcdir/buildx
make -j${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libxyce", :libxyce),
    LibraryProduct("libNeuronModels", :libNeuronModels),
    LibraryProduct("libADMS", :libADMS),
    ExecutableProduct("Xyce", :Xyce)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="SuiteSparse_jll", uuid="bea87d4a-7f5b-5778-9afe-8cc45184846c"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
    Dependency(PackageSpec(name="Gettext_jll", uuid="78b55507-aeef-58d4-861c-77aaff3498b1"))
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"6.1.0")
