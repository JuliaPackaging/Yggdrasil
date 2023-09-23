# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "Trilinos"
# Not a real version - this is 12.12.1, but needed a bump to change julia compat
version = v"14.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/trilinos/Trilinos.git", "975307431d60d0859ebaa27c9169cbb1d4287513"),
    DirectorySource("./bundled"),
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
atomic_patch -p1 $WORKSPACE/srcdir/patches/kokkostpl.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/tekoepetraguard.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/teuchoswinexport.patch

mkdir trilbuild
cd trilbuild
install_license ${WORKSPACE}/srcdir/Trilinos/LICENSE
SRCDIR="/workspace/srcdir/Trilinos"
FLAGS='-O3 -fPIC'
# TODO: This is a bug in Yggdrasil's GCC distribution
FLAGS+=" -D_GLIBCXX_HAVE_ALIGNED_ALLOC"
CMAKE_FLAGS="-DCMAKE_INSTALL_PREFIX=$prefix"
# Trilinos package enables
CMAKE_FLAGS="${CMAKE_FLAGS}
    -DTrilinos_ENABLE_NOX=ON -DNOX_ENABLE_ABSTRACT_IMPLEMENTATION_EPETRA=ON
    -DNOX_ENABLE_LOCA=ON
    -DTrilinos_ENABLE_EpetraExt=ON -DEpetraExt_BUILD_BTF=ON -DEpetraExt_BUILD_EXPERIMENTAL=ON -DEpetraExt_BUILD_GRAPH_REORDERINGS=ON
    -DTrilinos_ENABLE_TrilinosCouplings=ON
    -DTrilinos_ENABLE_Ifpack=ON
    -DTrilinos_ENABLE_Isorropia=ON
    -DTrilinos_ENABLE_AztecOO=ON
    -DTrilinos_ENABLE_Belos=ON
    -DTrilinos_ENABLE_Teuchos=ON
    -DTrilinos_ENABLE_Amesos=ON -DAmesos_ENABLE_KLU=ON
    -DTrilinos_ENABLE_Sacado=ON
    -DTrilinos_ENABLE_Rhytmos=ON
    -DTrilinos_ENABLE_Panzer=ON -DTrilinos_ENABLE_PanzerCore=ON -DTrilinos_ENABLE_PanzerDiscFE=ON -DTrilinos_ENABLE_PanzerAdaptersSTK=ON
    -DTrilinos_ENABLE_SEACAS=ON
    -DTrilinos_ENABLE_Piro=ON
    -DTrilinos_ENABLE_Stratimikos=ON
    -DTrilinos_ENABLE_STK=ON -DTrilinos_ENABLE_STKMesh=ON
    "

# Kokkos-dependent enables
# Kokkos is not available on all platforms, so only enable Kokkos-dependent things if it is available
if [ -f "/workspace/destdir/lib/cmake/Kokkos/KokkosConfig.cmake" ]; then
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTrilinos_ENABLE_Tpetra=ON -DTrilinos_ENABLE_Teko=ON"
else
    CMAKE_FLAGS="${CMAKE_FLAGS} -DTPL_ENABLE_Kokkos=OFF"
fi

# Global Trilinos FLAGS
CMAKE_FLAGS="${CMAKE_FLAGS}
    -DBUILD_SHARED_LIBS=ON
    -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF
    -DTrilinos_ENABLE_CXX11=ON -DCMAKE_BUILD_TYPE=Release
    -DTrilinos_ENABLE_OpenMP=ON -DTrilinos_ENABLE_COMPLEX_DOUBLE=ON
    -DTPL_ENABLE_X11=OFF -DTPL_ENABLE_MPI=ON
    "
# SuiteSparse config
CMAKE_FLAGS="${CMAKE_FLAGS} -DTPL_ENABLE_AMD=ON -DAMD_LIBRARY_DIRS=\"/${libdir}\"
    -DAMD_LIBRARY_NAMES=\"libsuitesparseconfig.${dlext}\;libamd.${dlext}\;libklu.${dlext}\;libcolamd.${dlext}\;libbtf.${dlext}\"
    -DAMD_INCLUDE_DIRS=\"${prefix}/include\" -DTPL_ENABLE_UMFPACK=ON -DUMFPACK_LIBRARY_DIRS=\"/${libdir}\"
    -DAMD_LIBRARY_NAMES=\"libumfpack.${dlext}\" -DTPL_UMFPACK_INCLUDE_DIRS=\"${prefix}/include\"
    -DTPL_UMFPACK_LIBRARIES=\"$libdir/libumfpack.${dlext}\" -DTPL_AMD_LIBRARIES=\"$libdir/libamd.${dlext}\"
    "
# BLAS/LAPACK config
CMAKE_FLAGS="${CMAKE_FLAGS}
    -DTPL_ENABLE_BLAS=ON -DTPL_ENABLE_LAPACK=ON -DBLAS_LIBRARY_DIRS=\"${prefix}/lib\" -DBLAS_LIBRARY_NAMES=\"${BLAS_NAME}.${dlext}\"
    -DLAPACK_LIBRARY_DIRS=\"${prefix}/lib\" -DLAPACK_LIBRARY_NAMES=\"${BLAS_NAME}.${dlext}\"
    "

# Trilinos tries to run a bunch of configure tests. Tell it what the output would have been.
CMAKE_FLAGS="${CMAKE_FLAGS}
    -DHAVE_GCC_ABI_DEMANGLE_EXITCODE=0
    -DHAVE_TEUCHOS_BLASFLOAT_EXITCODE=0 -DHAVE_TEUCHOS_BLASFLOAT_DOUBLE_RETURN_EXITCODE=0
    -DCXX_COMPLEX_BLAS_WORKS_EXITCODE=0 -DLAPACK_SLAPY2_WORKS_EXITCODE=0
    -DHAVE_TEUCHOS_LAPACKLARND_EXITCODE=0 -DKK_BLAS_RESULT_AS_POINTER_ARG_EXITCODE=0
    -DHAVE_GCC_ABI_DEMANGLE_EXITCODE__TRYRUN_OUTPUT=''
    -DHAVE_TEUCHOS_BLASFLOAT_EXITCODE__TRYRUN_OUTPUT=''
    -DLAPACK_SLAPY2_WORKS_EXITCODE__TRYRUN_OUTPUT=''
    -DCXX_COMPLEX_BLAS_WORKS_EXITCODE__TRYRUN_OUTPUT=''
    -DHAVE_TEUCHOS_LAPACKLARND_EXITCODE__TRYRUN_OUTPUT=''
    -DKK_BLAS_RESULT_AS_POINTER_ARG_EXITCODE__TRYRUN_OUTPUT=''
    "

cmake -G "Unix Makefiles" ${CMAKE_FLAGS} -DCMAKE_CXX_FLAGS="${FLAGS}" -DCMAKE_C_FLAGS="${FLAGS}" -DCMAKE_Fortran_FLAGS="${FLAGS}" $SRCDIR

make -j${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

# Filter libgfortran3 - the corresponding GCC is too old to compiler some of
# the newer C++ constructs.
filter!(platforms) do p
    !(p["libgfortran_version"] in ("3.0.0", "4.0.0"))
end

# MPI Handling
augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""
platforms, platform_dependencies = MPI.augment_platforms(platforms)

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
    Dependency(PackageSpec(name="Kokkos_jll", uuid="c1216c3d-6bb3-5a2b-bbbf-529b35eba709"))
    Dependency(PackageSpec(name="NetCDF_jll", uuid="7243133f-43d8-5620-bbf4-c2c921802cf3"))
    Dependency(PackageSpec(name="Matio_jll", uuid="f34749e5-bf11-50ef-9bf7-447477e32da8"))
    HostBuildDependency(PackageSpec(name="CMake_jll", uuid="3f4e10e2-61f2-5801-8945-23b9d642d0e6"))
]
append!(dependencies, platform_dependencies)

push!(dependencies,
   # On Intel Linux platforms we use glibc 2.12, but building STKMesh
   # requires 2.16+.
   # TODO: Can be removed after https://github.com/JuliaPackaging/BinaryBuilderBase.jl/pull/318
   BuildDependency(PackageSpec(name = "Glibc_jll", version = v"2.17");
                              platforms=filter(p -> libc(p) == "glibc" && proc_family(p) == "intel", platforms)))

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"10", julia_compat="1.10", augment_platform_block)
