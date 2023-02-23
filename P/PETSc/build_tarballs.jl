using BinaryBuilder
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "PETSc"
version = v"3.16.8"
petsc_version = v"3.16.6"
PARMETIS_COMPAT_VERSION = "4.0.5"
MUMPS_COMPAT_VERSION = "5.5.1"
SUITESPARSE_COMPAT_VERSION = "5.10.1"
SUPERLUDIST_COMPAT_VERSION = "8.0.1"
METIS_COMPAT_VERSION = "5.1.1"
SCOTCH_COMPAT_VERSION = "6.1.3"
SCALAPACK_COMPAT_VERSION = "2.2.1"

# Collection of sources required to build PETSc. Avoid using the git repository, it will
# require building SOWING which fails in all non-linux platforms.
sources = [
    ArchiveSource("https://www.mcs.anl.gov/petsc/mirror/release-snapshots/petsc-$(petsc_version).tar.gz",
    "bfc836b52f57686b583c16ab7fae0c318a7b28141ca01656ad673c8ca23037fa"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/petsc*
atomic_patch -p1 $WORKSPACE/srcdir/patches/petsc_name_mangle.patch

BLAS_LAPACK_LIB="${libdir}/libopenblas.${dlext}"

if [[ "${target}" == *-mingw* ]]; then
    #atomic_patch -p1 $WORKSPACE/srcdir/patches/fix-header-cases.patch
    MPI_LIBS="${libdir}/msmpi.${dlext}"
else
    if grep -q MPICH_NAME $prefix/include/mpi.h; then
        MPI_FFLAGS=
        MPI_LIBS="[${libdir}/libmpifort.${dlext},${libdir}/libmpi.${dlext}]"
    elif grep -q MPItrampoline $prefix/include/mpi.h; then
        MPI_FFLAGS="-fcray-pointer"
        MPI_LIBS="[${libdir}/libmpitrampoline.${dlext}]"
    elif grep -q OMPI_MAJOR_VERSION $prefix/include/mpi.h; then
        MPI_FFLAGS=
        MPI_LIBS="[${libdir}/libmpi_usempif08.${dlext},${libdir}/libmpi_usempi_ignore_tkr.${dlext},${libdir}/libmpi_mpifh.${dlext},${libdir}/libmpi.${dlext}]"
    else
        MPI_FFLAGS=
        MPI_LIBS=
    fi
fi

atomic_patch -p1 $WORKSPACE/srcdir/patches/mingw-version.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/mpi-constants.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/sosuffix.patch

mkdir $libdir/petsc
build_petsc()
{
    PETSC_CONFIG="${1}_${2}_${3}"
    if [[ "${3}" == "Int64" ]]; then
        USE_INT64=1
    else
        USE_INT64=0
    fi

    # A SuperLU_DIST build is (now) available on most systems, but only works for double precision
    USE_SUPERLU_DIST=0    
    SUPERLU_DIST_LIB=""
    SUPERLU_DIST_INCLUDE=""
    if [ -d "${libdir}/superlu_dist" ] &&  [ "${1}" == "double" ]; 
    then
        USE_SUPERLU_DIST=1    
        SUPERLU_DIR="${libdir}/superlu_dist/${3}"
        SUPERLU_DIST_LIB="--with-superlu_dist-lib=${SUPERLU_DIR}/lib/libsuperlu_dist_${3}.${dlext}"
        SUPERLU_DIST_INCLUDE="--with-superlu_dist-include=${SUPERLU_DIR}/include"
    fi
    
    USE_SUITESPARSE=0
    if [ "${1}" == "double" ]; then
        USE_SUITESPARSE=1    
    fi

    Machine_name=$(uname -m)
    if [ "${3}" == "Int64" ]; then
        case "${Machine_name}" in
            "armv7l")
                USE_SUITESPARSE=0
            ;;
            "armv6l")
                USE_SUITESPARSE=0
            ;;
            "i686")
                USE_SUITESPARSE=0
            ;;
        esac
    fi

    # See if we can install MUMPS
    USE_MUMPS=0    
    if [ -f "${libdir}/libdmumps.${dlext}" ] && [ "${1}" == "double" ]; then
        USE_MUMPS=1    
        MUMPS_LIB="--with-mumps-lib=${libdir}/libdmumps.${dlext} --with-scalapack-lib=${libdir}/libscalapack32.${dlext}"
        MUMPS_INCLUDE="--with-mumps-include=${includedir} --with-scalapack-include=${includedir}"
    else
        MUMPS_LIB=""
        MUMPS_INCLUDE=""
    fi

    echo "USE_SUPERLU_DIST="$USE_SUPERLU_DIST
    echo "USE_SUITESPARSE="$USE_SUITESPARSE
    echo "USE_MUMPS="$USE_MUMPS
    echo "1="${1}
    echo "2="${2}
    echo "3="${3}
    echo "USE_INT64"=$USE_INT64
    echo "Machine_name="$Machine_name
    
    mkdir $libdir/petsc/${PETSC_CONFIG}
    ./configure --prefix=${libdir}/petsc/${PETSC_CONFIG} \
        CC=${CC} \
        FC=${FC} \
        CXX=${CXX} \
        COPTFLAGS='-O3' \
        CXXOPTFLAGS='-O3' \
        CFLAGS='-fno-stack-protector' \
        FFLAGS="${MPI_FFLAGS}" \
        LDFLAGS="-L${libdir}" \
        FOPTFLAGS='-O3' \
        --with-64-bit-indices=${USE_INT64} \
        --with-debugging=0 \
        --with-batch \
        --with-blaslapack-lib=$BLAS_LAPACK_LIB \
        --with-blaslapack-suffix="" \
        --with-superlu_dist=${USE_SUPERLU_DIST} \
        ${SUPERLU_DIST_LIB} \
        ${SUPERLU_DIST_INCLUDE} \
        --with-mumps=${USE_MUMPS} \
        ${MUMPS_LIB} \
        ${MUMPS_INCLUDE} \
        --with-suitesparse=${USE_SUITESPARSE} \
        --known-64-bit-blas-indices=0 \
        --with-mpi-lib="${MPI_LIBS}" \
        --known-mpi-int64_t=0 \
        --with-mpi-include="${includedir}" \
        --with-sowing=0 \
        --with-precision=${1} \
        --with-scalar-type=${2} \
        --PETSC_ARCH=${target}_${PETSC_CONFIG} \
        --SOSUFFIX=${PETSC_CONFIG}

    if [[ "${target}" == *-mingw* ]]; then
        export CPPFLAGS="-Dpetsc_EXPORTS"
    elif [[ "${target}" == powerpc64le-* ]]; then
        export CFLAGS="-fPIC"
        export FFLAGS="-fPIC"
    fi

    make -j${nproc} \
        CPPFLAGS="${CPPFLAGS}" \
        CFLAGS="${CFLAGS}" \
        FFLAGS="${FFLAGS}"
    make install

    # Remove PETSc.pc because petsc.pc also exists, causing conflicts on case insensitive file-systems.
    rm ${libdir}/petsc/${PETSC_CONFIG}/lib/pkgconfig/PETSc.pc
    # sed -i -e "s/-lpetsc/-lpetsc_${PETSC_CONFIG}/g" "$libdir/petsc/${PETSC_CONFIG}/lib/pkgconfig/petsc.pc"
    # cp $libdir/petsc/${PETSC_CONFIG}/lib/pkgconfig/petsc.pc ${prefix}/lib/pkgconfig/petsc_${PETSC_CONFIG}.pc

    # we don't particularly care about the examples
    rm -r ${libdir}/petsc/${PETSC_CONFIG}/share/petsc/examples
}

build_petsc double real Int32
build_petsc single real Int32
build_petsc double complex Int32
build_petsc single complex Int32
build_petsc double real Int64
build_petsc single real Int64
build_petsc double complex Int64
build_petsc single complex Int64
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# We attempt to build for all defined platforms
platforms = expand_gfortran_versions(supported_platforms(exclude=[Platform("i686", "windows")]))
platforms, platform_dependencies = MPI.augment_platforms(platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)

# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

products = [
    # Current default build, equivalent to Float64_Real_Int32
    LibraryProduct("libpetsc_double_real_Int32", :libpetsc, "\$libdir/petsc/double_real_Int32/lib")
    LibraryProduct("libpetsc_double_real_Int32", :libpetsc_Float64_Real_Int32, "\$libdir/petsc/double_real_Int32/lib")
    LibraryProduct("libpetsc_single_real_Int32", :libpetsc_Float32_Real_Int32, "\$libdir/petsc/single_real_Int32/lib")
    LibraryProduct("libpetsc_double_complex_Int32", :libpetsc_Float64_Complex_Int32, "\$libdir/petsc/double_complex_Int32/lib")
    LibraryProduct("libpetsc_single_complex_Int32", :libpetsc_Float32_Complex_Int32, "\$libdir/petsc/single_complex_Int32/lib")
    LibraryProduct("libpetsc_double_real_Int64", :libpetsc_Float64_Real_Int64, "\$libdir/petsc/double_real_Int64/lib")
    LibraryProduct("libpetsc_single_real_Int64", :libpetsc_Float32_Real_Int64, "\$libdir/petsc/single_real_Int64/lib")
    LibraryProduct("libpetsc_double_complex_Int64", :libpetsc_Float64_Complex_Int64, "\$libdir/petsc/double_complex_Int64/lib")
    LibraryProduct("libpetsc_single_complex_Int64", :libpetsc_Float32_Complex_Int64, "\$libdir/petsc/single_complex_Int64/lib")
]

dependencies = [
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("SuperLU_DIST_jll"; compat=SUPERLUDIST_COMPAT_VERSION),
    Dependency("SuiteSparse_jll"; compat=SUITESPARSE_COMPAT_VERSION),
    Dependency("MUMPS_jll"; compat=MUMPS_COMPAT_VERSION),
    Dependency("SCALAPACK32_jll"; compat=SCALAPACK_COMPAT_VERSION),
    Dependency("METIS_jll"; compat=METIS_COMPAT_VERSION),
    Dependency("SCOTCH_jll"; compat=SCOTCH_COMPAT_VERSION),
    Dependency("PARMETIS_jll"; compat=PARMETIS_COMPAT_VERSION),
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and
# `dlopen`s the shared libraries. (MPItrampoline will skip its
# automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version = v"9")
