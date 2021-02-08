# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Trilinos"
version = v"13.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/trilinos/Trilinos.git", "4796b92fb0644ba8c531dd9953e7a4878b05c62d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
install_license ${WORKSPACE}/srcdir/Trilinos/LICENSE
mkdir buildt
cd buildt
FLAGS="-O3 -fPIC"
cmake /workspace/srcdir/Trilinos -G "Unix Makefiles" -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DTrilinos_ENABLE_Fortran=OFF -DCMAKE_CXX_FLAGS="$FLAGS" -DCMAKE_C_FLAGS="$FLAGS" -DCMAKE_MAKE_PROGRAM="make" -DBUILD_SHARED_LIBS=ON -DTrilinos_ENABLE_NOX=ON -DNOX_ENABLE_LOCA=ON -DTrilinos_ENABLE_EpetraExt=ON -DEpetraExt_BUILD_BTF=ON -DEpetraExt_BUILD_EXPERIMENTAL=ON -DEpetraExt_BUILD_GRAPH_REORDERINGS=ON -DTrilinos_ENABLE_TrilinosCouplings=ON -DTrilinos_ENABLE_Ifpack=ON -DTrilinos_ENABLE_Isorropia=ON -DTrilinos_ENABLE_AztecOO=ON -DTrilinos_ENABLE_Teuchos=ON -DTeuchos_ENABLE_COMPLEX=ON -DTrilinos_ENABLE_Amesos=ON -DAmesos_ENABLE_KLU=ON -DTrilinos_ENABLE_Sacado=ON -DTrilinos_ENABLE_Kokkos=OFF -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF -DTrilinos_ENABLE_CXX11=ON -DTPL_ENABLE_AMD=ON -DAMD_LIBRARY_DIRS="/$prefix/lib" -DTPL_AMD_INCLUDE_DIRS="$prefix/include/" -DTPL_BLAS_LIBRARIES='${prefix}/lib/' -DTPL_LAPACK_LIBRARIES="/$prefix/bin/" -DTPL_BLAS_INCLUDE_DIRS='${prefix}/include/cblas;${prefix}/include/f77blas' -DTPL_LAPACK_INCLUDE_DIRS="$prefix/include/lapack" -DTrilinos_SET_INSTALL_RPATH=FALSE -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=FALSE -DCMAKE_INSTALL_RPATH=$prefix/lib -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_BUILD_TYPE=Release
make -j${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc)
]

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libaztecoo", :libaztecoo),
    LibraryProduct("libnoxepetra", :libnoxepetra),
    LibraryProduct("libloca", :libloca),
    LibraryProduct("liblocalapack", :liblocalapack),
    LibraryProduct("liblocaepetra", :liblocaepetra),
    LibraryProduct("libepetra", :libepetra),
    LibraryProduct("libteuchosremainder", :libteuchosremainder),
    LibraryProduct("libsimpi", :libsimpi),
    LibraryProduct("libnoxlapack", :libnoxlapack),
    LibraryProduct("libteuchosparameterlist", :libteuchosparameterlist),
    LibraryProduct("libteuchoscore", :libteuchoscore),
    LibraryProduct("libtrilinoscouplings", :libtrilinoscouplings),
    LibraryProduct("libnox", :libnox),
    LibraryProduct("libteuchosparser", :libteuchosparser),
    LibraryProduct("libteuchosnumerics", :libteuchosnumerics),
    LibraryProduct("libtrilinosss", :libtrilinosss),
    LibraryProduct("libisorropia", :libisorropia),
    LibraryProduct("libzoltan", :libzoltan),
    LibraryProduct("libepetraext", :libepetraext),
    LibraryProduct("libifpack", :libifpack),
    LibraryProduct("libtriutils", :libtriutils),
    LibraryProduct("libsacado", :libsacado),
    LibraryProduct("libteuchoscomm", :libteuchoscomm),
    LibraryProduct("libamesos", :libamesos)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="SuiteSparse_jll", uuid="bea87d4a-7f5b-5778-9afe-8cc45184846c"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0")