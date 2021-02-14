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
mkdir build
cd build
install_license ${WORKSPACE}/srcdir/Trilinos/LICENSE
SRCDIR="/workspace/srcdir/Trilinos"
FLAGS="-O3 -fPIC"
cmake -G "Unix Makefiles" -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DCMAKE_Fortran_COMPILER=gfortran \
    -DCMAKE_CXX_FLAGS="$FLAGS" -DCMAKE_C_FLAGS="$FLAGS" -DCMAKE_Fortran_FLAGS="$FLAGS" -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_MAKE_PROGRAM="make" -DTrilinos_ENABLE_NOX=ON   -DNOX_ENABLE_LOCA=ON \
    -DTrilinos_ENABLE_EpetraExt=ON   -DEpetraExt_BUILD_BTF=ON   -DEpetraExt_BUILD_EXPERIMENTAL=ON   \
    -DEpetraExt_BUILD_GRAPH_REORDERINGS=ON -DTrilinos_ENABLE_TrilinosCouplings=ON -DTrilinos_ENABLE_Ifpack=ON \
    -DTrilinos_ENABLE_Isorropia=ON -DTrilinos_ENABLE_AztecOO=ON -DTrilinos_ENABLE_Belos=ON -DTrilinos_ENABLE_Teuchos=ON \
    -DTeuchos_ENABLE_COMPLEX=ON -DTrilinos_ENABLE_Amesos=ON   -DAmesos_ENABLE_KLU=ON -DTrilinos_ENABLE_Sacado=ON \
    -DTrilinos_ENABLE_Kokkos=OFF -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF -DTrilinos_ENABLE_CXX11=ON \
    -DTPL_ENABLE_AMD=ON -DAMD_LIBRARY_DIRS="/${libdir}" -DTPL_ENABLE_BLAS=ON -DTPL_ENABLE_LAPACK=ON \
    -DBLAS_LIBRARY_DIRS="${prefix}/lib" -DBLAS_LIBRARY_NAMES="libopenblas.${dlext}" -DLAPACK_LIBRARY_DIRS="${prefix}/lib" \
    -DLAPACK_LIBRARY_NAMES="libopenblas.${dlext}" -DTrilinos_SET_INSTALL_RPATH=FALSE \
    -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=FALSE -DCMAKE_INSTALL_RPATH=$prefix -DCMAKE_BUILD_TYPE=Release $SRCDIR
make -j${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
#platforms = [ Platform("x86_64", "linux"; libc="glibc"),]
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libaztecoo", :libaztecoo),
    LibraryProduct("liblocalapack", :liblocalapack),
    LibraryProduct("libifpack", :libifpack),
    LibraryProduct("libloca", :libloca),
    LibraryProduct("libzoltan", :libzoltan),
    LibraryProduct("libisorropia", :libisorropia),
    LibraryProduct("libbelos", :libbelos),
    LibraryProduct("libteuchosparameterlist", :libteuchosparameterlist),
    LibraryProduct("libnoxlapack", :libnoxlapack),
    LibraryProduct("libnox", :libnox),
    LibraryProduct("libteuchoscore", :libteuchoscore),
    LibraryProduct("libsimpi", :libsimpi),
    LibraryProduct("libteuchosremainder", :libteuchosremainder),
    LibraryProduct("liblocaepetra", :liblocaepetra),
    LibraryProduct("libteuchosnumerics", :libteuchosnumerics),
    LibraryProduct("libteuchoscomm", :libteuchoscomm),
    LibraryProduct("libtrilinoscouplings", :libtrilinoscouplings),
    LibraryProduct("libepetraext", :libepetraext),
    LibraryProduct("libtriutils", :libtriutils),
    LibraryProduct("libbelosepetra", :libbelosepetra),
    LibraryProduct("libepetra", :libepetra),
    LibraryProduct("libtrilinosss", :libtrilinosss),
    LibraryProduct("libnoxepetra", :libnoxepetra),
    LibraryProduct("libsacado", :libsacado),
    LibraryProduct("libamesos", :libamesos)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
    Dependency(PackageSpec(name="SuiteSparse32_jll", uuid="ca45d3f4-326b-53b0-9957-23b75aacb3f2"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7")
