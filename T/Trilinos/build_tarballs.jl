# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Trilinos"
version = v"13.0"
# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/trilinos/Trilinos.git", "9fec35276d846a667bc668ff4cbdfd8be0dfea08")
]

# We are manually specifying the compilers rather than using the toolchain file.
# Does not build due to TRY_RUN errors with TEUCHOS, BLAS, and company.
# Much of this is lifted directly from the Debian build script.
# Specifically to avoid accidentally building additional products we explicitly enable or
# disable all major packages.
script = raw"""
cd $WORKSPACE/srcdir
mkdir trilbuild
cd trilbuild
install_license ${WORKSPACE}/srcdir/Trilinos/LICENSE
SRCDIR="/workspace/srcdir/Trilinos"
FLAGS="-O3 -fPIC"
cmake \
    -DCMAKE_C_COMPILER=cc \
    -DCMAKE_CXX_COMPILER=c++ \
    -DCMAKE_Fortran_COMPILER=gfortran \
    -DCMAKE_CXX_FLAGS="$FLAGS" -DCMAKE_C_FLAGS="$FLAGS" \
    -DCMAKE_Fortran_FLAGS="$FLAGS" \
    -DTrilinos_ENABLE_DEVELOPMENT_MODE=OFF \
    -DTrilinos_ASSERT_MISSING_PACKAGES=OFF \
    -DTrilinos_ENABLE_EXPLICIT_INSTANTIATION=ON \
    -DTrilinos_ENABLE_EXPORT_MAKEFILES=OFF \
    -DTrilinos_ENABLE_EXAMPLES=OFF \
    -DTrilinos_ENABLE_TESTS=OFF \
    -DTrilinos_ENABLE_CXX11=ON \
    -DCMAKE_MAKE_PROGRAM="make" \
    -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DBUILD_SHARED_LIBS=ON \
    -DTPL_ENABLE_AMD=ON \
    -DAMD_LIBRARY_DIRS="${libdir}" \
    -DAMD_LIBRARY_NAMES="libsuitesparseconfig.${dlext};libamd.${dlext};libklu.${dlext};libcolamd.${dlext};libbtf.${dlext}" \
    -DTPL_AMD_INCLUDE_DIRS="${includedir}" \
    -DTPL_ENABLE_UMFPACK=ON \
    -DUMFPACK_LIBRARY_DIRS="${libdir}" \
    -DUMFPACK_LIBRARY_NAMES="libsuitesparseconfig.${dlext};libamd.${dlext};libumfpack.${dlext}" \
    -DTPL_UMFPACK_INCLUDE_DIRS="${includedir}" \
    -DTPL_ENABLE_Cholmod=ON \
    -DCholmod_LIBRARY_DIRS="${libdir}" \
    -DCholmod_LIBRARY_NAMES="libsuitesparseconfig.${dlext};libamd.${dlext};libcholmod.${dlext};libcolamd.${dlext}" \
    -DBLAS_LIBRARY_DIRS="${libdir}" \
    -DBLAS_LIBRARY_NAMES="libopenblas.${dlext}" \
    -DLAPACK_LIBRARY_DIRS="${libdir}" \
    -DLAPACK_LIBRARY_NAMES="libopenblas.${dlext}" \
    -DTrilinos_ENABLE_OpenMP=ON \
    -DTrilinos_ENABLE_COMPLEX=ON \
    -DTrilinos_ENABLE_Amesos=ON \
    -DTrilinos_ENABLE_Amesos2=ON  \
    -DTrilinos_ENABLE_Anasazi=ON  \
    -DTrilinos_ENABLE_AztecOO=ON \
    -DTrilinos_ENABLE_Belos=ON  \
    -DTrilinos_ENABLE_Epetra=ON  \
    -DTrilinos_ENABLE_EpetraExt=ON \
    -DTrilinos_ENABLE_Galeri=ON \
    -DTrilinos_ENABLE_Ifpack=ON  \
    -DTrilinos_ENABLE_Ifpack2=ON \
    -DTrilinos_ENABLE_Intrepid=ON \
    -DTrilinos_ENABLE_Intrepid2=ON \
    -DTrilinos_ENABLE_Isorropia=ON \
    -DTrilinos_ENABLE_Kokkos=ON \
    -DTrilinos_ENABLE_KokkosKernels=ON \
    -DTrilinos_ENABLE_Komplex=ON \
    -DTrilinos_ENABLE_ML=ON \
    -DTrilinos_ENABLE_Moertel=ON \
    -DTrilinos_ENABLE_MueLu=ON  \
    -DTrilinos_ENABLE_NOX=ON  \
    -DTrilinos_ENABLE_Pamgen=ON \
    -DTrilinos_ENABLE_Phalanx=ON \
    -DTrilinos_ENABLE_Pike=ON \
    -DTrilinos_ENABLE_Piro=ON  \
    -DTrilinos_ENABLE_Pliris=ON \
    -DTrilinos_ENABLE_ROL=ON \
    -DTrilinos_ENABLE_RTOp=ON \
    -DTrilinos_ENABLE_Rythmos=ON \
    -DTrilinos_ENABLE_Sacado=ON \
    -DTrilinos_ENABLE_Shards=ON \
    -DTrilinos_ENABLE_ShyLU=OFF \
    -DTrilinos_ENABLE_Stokhos=ON \
    -DTrilinos_ENABLE_Stratimikos=ON  \
    -DTrilinos_ENABLE_Teko=ON \
    -DTrilinos_ENABLE_Teuchos=ON  \
    -DTrilinos_ENABLE_Thyra=ON \
    -DTrilinos_ENABLE_Tpetra=ON \
    -DTrilinos_ENABLE_TrilinosCouplings=ON \
    -DTrilinos_ENABLE_Triutils=ON \
    -DTrilinos_ENABLE_Xpetra=ON  \
    -DTrilinos_ENABLE_Zoltan=ON  \
    -DTrilinos_ENABLE_Zoltan2=ON  \
    -DTrilinos_ENABLE_Gtest=OFF \
    -DTrilinos_ENABLE_MiniTensor=OFF \
    -DTrilinos_ENABLE_SEACAS=OFF \
    -DTrilinos_ENABLE_STK=OFF \
    -DTrilinos_ENABLE_Tempus=ON \
    -DTPL_ENABLE_BinUtils=OFF \
    -DTPL_ENABLE_Boost=OFF \
    -DTPL_ENABLE_HDF5=OFF \
    -DTPL_ENABLE_Matio=OFF \
    -DTPL_ENABLE_MATLAB=OFF \
    -DTPL_ENABLE_MPI=ON \
    -DTPL_ENABLE_MUMPS=OFF \
    -DTPL_ENABLE_Netcdf=OFF \
    -DTPL_ENABLE_ParMETIS=OFF \
    -DTPL_ENABLE_Scotch=OFF \
    -DTPL_ENABLE_SuperLU=OFF \
    -DTPL_ENABLE_TBB=OFF \
    -DTPL_ENABLE_X11=OFF \
    -DTPL_ENABLE_Zlib=OFF \
    -DTrilinos_ENABLE_PyTrilinos=OFF \
    -DTrilinos_DUMP_PACKAGE_DEPENDENCIES=ON \
    $SRCDIR
    make -j${nprocs} install
        """

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> (Sys.islinux(p) && nbits(p) != 32), supported_platforms())

platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = LibraryProduct[
    #LibraryProduct("libamesos2", :libamesos2),
    #LibraryProduct("libamesos", :libamesos),
    #LibraryProduct("libanasaziepetra", :libanasaziepetra),
    #LibraryProduct("libanasazi", :libanasazi),
    #LibraryProduct("libanasazitpetra", :libanasazitpetra),
    #LibraryProduct("libaztecoo", :libaztecoo),
    #LibraryProduct("libbelosepetra", :libbelosepetra),
    #LibraryProduct("libbelos", :libbelos),
    #LibraryProduct("libbelostpetra", :libbelostpetra),
    #LibraryProduct("libdpliris", :libdpliris),
    #LibraryProduct("libepetraext", :libepetraext),
    #LibraryProduct("libepetra", :libepetra),
    #LibraryProduct("libgaleri-epetra", :libgaleri_epetra),
    #LibraryProduct("libgaleri-xpetra", :libgaleri_xpetra),
    #LibraryProduct("libifpack2-adapters", :libifpack2_adapters),
    #LibraryProduct("libifpack2", :libifpack2),
    #LibraryProduct("libifpack", :libifpack),
    #LibraryProduct("libintrepid2", :libintrepid2),
    #LibraryProduct("libintrepid", :libintrepid),
    #LibraryProduct("libisorropia", :libisorropia),
    #LibraryProduct("libkokkosalgorithms", :libkokkosalgorithms),
    #LibraryProduct("libkokkoscontainers", :libkokkoscontainers),
    #LibraryProduct("libkokkoscore", :libkokkoscore),
    #LibraryProduct("libkokkoskernels", :libkokkoskernels),
    #LibraryProduct("libkokkostsqr", :libkokkostsqr),
    #LibraryProduct("libkomplex", :libkomplex),
    #LibraryProduct("liblocaepetra", :liblocaepetra),
    #LibraryProduct("liblocalapack", :liblocalapack),
    #LibraryProduct("libloca", :libloca),
    #LibraryProduct("liblocathyra", :liblocathyra),
    #LibraryProduct("libml", :libml),
    #LibraryProduct("libModeLaplace", :libModeLaplace),
    #LibraryProduct("libmoertel", :libmoertel),
    #LibraryProduct("libmuelu-adapters", :libmuelu_adapters),
    #LibraryProduct("libmuelu-interface", :libmuelu_interface),
    #LibraryProduct("libmuelu", :libmuelu),
    #LibraryProduct("libnoxepetra", :libnoxepetra),
    #LibraryProduct("libnoxlapack", :libnoxlapack),
    #LibraryProduct("libnox", :libnox),
    #LibraryProduct("libpamgen_extras", :libpamgen_extras),
    #LibraryProduct("libpamgen", :libpamgen),
    #LibraryProduct("libphalanx", :libphalanx),
    #LibraryProduct("libpiro", :libpiro),
    #LibraryProduct("librol", :librol),
    #LibraryProduct("librtop", :librtop),
    #LibraryProduct("librythmos", :librythmos),
    #LibraryProduct("libsacado", :libsacado),
    #LibraryProduct("libshards", :libshards),
    #LibraryProduct("libstokhos_amesos2", :libstokhos_amesos2),
    #LibraryProduct("libstokhos_ifpack2", :libstokhos_ifpack2),
    #LibraryProduct("libstokhos_muelu", :libstokhos_muelu),
    #LibraryProduct("libstokhos_sacado", :libstokhos_sacado),
    #LibraryProduct("libstokhos", :libstokhos),
    #LibraryProduct("libstokhos_tpetra", :libstokhos_tpetra),
    #LibraryProduct("libstratimikosamesos", :libstratimikosamesos),
    #LibraryProduct("libstratimikosaztecoo", :libstratimikosaztecoo),
    #LibraryProduct("libstratimikosbelos", :libstratimikosbelos),
    #LibraryProduct("libstratimikosifpack", :libstratimikosifpack),
    #LibraryProduct("libstratimikosml", :libstratimikosml),
    #LibraryProduct("libstratimikos", :libstratimikos),
    #LibraryProduct("libteko", :libteko),
    #LibraryProduct("libtempus", :libtempus),
    #LibraryProduct("libteuchoscomm", :libteuchoscomm),
    #LibraryProduct("libteuchoscore", :libteuchoscore),
    #LibraryProduct("libteuchoskokkoscomm", :libteuchoskokkoscomm),
    #LibraryProduct("libteuchoskokkoscompat", :libteuchoskokkoscompat),
    #LibraryProduct("libteuchosnumerics", :libteuchosnumerics),
    #LibraryProduct("libteuchosparameterlist", :libteuchosparameterlist),
    #LibraryProduct("libteuchosremainder", :libteuchosremainder),
    #LibraryProduct("libthyracore", :libthyracore),
    #LibraryProduct("libthyraepetraext", :libthyraepetraext),
    #LibraryProduct("libthyraepetra", :libthyraepetra),
    #LibraryProduct("libthyratpetra", :libthyratpetra),
    #LibraryProduct("libtpetraclassiclinalg", :libtpetraclassiclinalg),
    #LibraryProduct("libtpetraclassicnodeapi", :libtpetraclassicnodeapi),
    #LibraryProduct("libtpetraclassic", :libtpetraclassic),
    #LibraryProduct("libtpetraext", :libtpetraext),
    #LibraryProduct("libtpetrainout", :libtpetrainout),
    #LibraryProduct("libtpetra", :libtpetra),
    #LibraryProduct("libtrilinoscouplings", :libtrilinoscouplings),
    #LibraryProduct("libtrilinosss", :libtrilinosss),
    #LibraryProduct("libtriutils", :libtriutils),
    #LibraryProduct("libxpetra", :libxpetra),
    #LibraryProduct("libxpetra-sup", :libxpetra_sup),
    #LibraryProduct("libzoltan", :libzoltan),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="SuiteSparse_jll", uuid="bea87d4a-7f5b-5778-9afe-8cc45184846c"))
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
    Dependency("MPICH_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0")
