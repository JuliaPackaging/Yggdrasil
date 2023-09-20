# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Trilinos"
# Not a real version - this is 12.12.1, but needed a bump to change julia compat
version = v"14.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/trilinos/Trilinos.git", "975307431d60d0859ebaa27c9169cbb1d4287513")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

if [[ "${target}" == *-mingw* ]]; then
    BLAS_NAME=libblastrampoline-5
else
    BLAS_NAME=libblastrampoline
fi

# Use newer cmake from the HostBuildDependency
rm /usr/bin/cmake

cd Trilinos

mkdir trilbuild
cd trilbuild
install_license ${WORKSPACE}/srcdir/Trilinos/LICENSE
SRCDIR="/workspace/srcdir/Trilinos"
FLAGS="-O3 -fPIC"
CMAKE_FLAGS="-DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}"
# Trilinos tries to run a bunch of configure tests. Tell it what the output would have been.
CMAKE_FLAGS="${CMAKE_FLAGS} -DHAVE_GCC_ABI_DEMANGLE_EXITCODE=0 -DHAVE_TEUCHOS_BLASFLOAT_EXITCODE=0 -DHAVE_TEUCHOS_BLASFLOAT_DOUBLE_RETURN_EXITCODE=0 -DCXX_COMPLEX_BLAS_WORKS_EXITCODE=0 -DLAPACK_SLAPY2_WORKS_EXITCODE=0 -DHAVE_GCC_ABI_DEMANGLE_EXITCODE__TRYRUN_OUTPUT='' -DHAVE_TEUCHOS_BLASFLOAT_EXITCODE__TRYRUN_OUTPUT='' -DLAPACK_SLAPY2_WORKS_EXITCODE__TRYRUN_OUTPUT='' -DCXX_COMPLEX_BLAS_WORKS_EXITCODE__TRYRUN_OUTPUT=''"
cmake -G "Unix Makefiles" ${CMAKE_FLAGS} -DCMAKE_CXX_FLAGS="$FLAGS" -DCMAKE_C_FLAGS="$FLAGS" -DCMAKE_Fortran_FLAGS="$FLAGS" -DBUILD_SHARED_LIBS=ON -DTrilinos_ENABLE_NOX=ON -DNOX_ENABLE_LOCA=ON -DTrilinos_ENABLE_EpetraExt=ON   -DEpetraExt_BUILD_BTF=ON   -DEpetraExt_BUILD_EXPERIMENTAL=ON -DEpetraExt_BUILD_GRAPH_REORDERINGS=ON -DTrilinos_ENABLE_TrilinosCouplings=ON -DTrilinos_ENABLE_Ifpack=ON -DTrilinos_ENABLE_Isorropia=ON -DTrilinos_ENABLE_AztecOO=ON -DTrilinos_ENABLE_Belos=ON -DTrilinos_ENABLE_Teuchos=ON -DTeuchos_ENABLE_COMPLEX=ON -DTrilinos_ENABLE_Amesos=ON -DAmesos_ENABLE_KLU=ON -DTrilinos_ENABLE_Sacado=ON -DTrilinos_ENABLE_Kokkos=OFF -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF -DTrilinos_ENABLE_CXX11=ON -DTPL_ENABLE_AMD=ON -DAMD_LIBRARY_DIRS="/${libdir}" -DAMD_LIBRARY_NAMES="libsuitesparseconfig.${dlext};libamd.${dlext};libklu.${dlext};libcolamd.${dlext};libbtf.${dlext}" -DAMD_INCLUDE_DIRS="${prefix}/include" -DTPL_ENABLE_UMFPACK=ON -DUMFPACK_LIBRARY_DIRS="/${libdir}" -DAMD_LIBRARY_NAMES="libumfpack.${dlext}" -DTPL_UMFPACK_INCLUDE_DIRS="${prefix}/include" -DTPL_ENABLE_BLAS=ON -DTPL_ENABLE_LAPACK=ON -DTPL_UMFPACK_LIBRARIES="$libdir/libumfpack.${dlext}" -DTPL_AMD_LIBRARIES="$libdir/libamd.${dlext}" -DBLAS_LIBRARY_DIRS="${prefix}/lib" -DBLAS_LIBRARY_NAMES="${BLAS_NAME}.${dlext}" -DLAPACK_LIBRARY_DIRS="${prefix}/lib" -DLAPACK_LIBRARY_NAMES="${BLAS_NAME}.${dlext}" -DCMAKE_BUILD_TYPE=Release $SRCDIR

make -j${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
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
    Dependency(PackageSpec(name="SuiteSparse_jll", uuid="bea87d4a-7f5b-5778-9afe-8cc45184846c"))
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
    HostBuildDependency(PackageSpec(name="CMake_jll", uuid="3f4e10e2-61f2-5801-8945-23b9d642d0e6"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0", julia_compat="1.10")
