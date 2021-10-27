using BinaryBuilder

name = "PETSc"
version = v"3.15.2"

# Collection of sources required to build PETSc. Avoid using the git repository, it will
# require building SOWING which fails in all non-linux platforms.
sources = [
    ArchiveSource("https://www.mcs.anl.gov/petsc/mirror/release-snapshots/petsc-$(version).tar.gz",
    "3b10c19c69fc42e01a38132668724a01f1da56f5c353105cd28f1120cc9041d8"),
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
    MPI_LIBS="[${libdir}/libmpifort.${dlext},${libdir}/libmpi.${dlext}]"
fi
mkdir $libdir/petsc
build_petsc()
{

    if [[ "${3}" == "Int64" ]]; then
        USE_INT64=1
    else
        USE_INT64=0
    fi
    mkdir $libdir/petsc/${1}_${2}_${3}
    ./configure --prefix=${libdir}/petsc/${1}_${2}_${3} \
        CC=${CC} \
        FC=${FC} \
        CXX=${CXX} \
        COPTFLAGS='-O3' \
        CXXOPTFLAGS='-O3' \
        CFLAGS='-fno-stack-protector' \
        LDFLAGS="-L${libdir}" \
        FOPTFLAGS='-O3' \
        --with-64-bit-indices=${USE_INT64} \
        --with-debugging=0 \
        --with-batch \
        --with-blaslapack-lib=$BLAS_LAPACK_LIB \
        --with-blaslapack-suffix="" \
        --known-64-bit-blas-indices=0 \
        --with-mpi-lib="${MPI_LIBS}" \
        --known-mpi-int64_t=0 \
        --with-mpi-include="${includedir}" \
        --with-sowing=0 \
        --with-precision=${1} \
        --with-scalar-type=${2} \
        --PETSC_ARCH=${target}_${1}_${2}_${3}

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

# We attempt to build for all defined platforms
platforms = expand_gfortran_versions(supported_platforms(exclude=[Platform("i686", "windows")]))

products = [
    # Current default build, equivalent to Float64_Real_Int32
    LibraryProduct("libpetsc", :libpetsc, "$libdir/petsc/double_real_Int32/lib")
    LibraryProduct("libpetsc", :libpetsc_Float64_Real_Int32, "$libdir/petsc/double_real_Int32/lib")
    LibraryProduct("libpetsc", :libpetsc_Float64_Real_Int64, "$libdir/petsc/double_real_Int64/lib")
    LibraryProduct("libpetsc", :libpetsc_Float32_Real_Int64, "$libdir/petsc/single_real_Int64/lib")
    LibraryProduct("libpetsc", :libpetsc_Float64_Complex_Int64, "$libdir/petsc/double_complex_Int64/lib")
    LibraryProduct("libpetsc", :libpetsc_Float32_Complex_Int64, "$libdir/petsc/single_complex_Int64/lib")
    LibraryProduct("libpetsc", :libpetsc_Float32_Real_Int32, "$libdir/petsc/single_real_Int32/lib")
    LibraryProduct("libpetsc", :libpetsc_Float64_Complex_Int32, "$libdir/petsc/double_complex_Int32/lib")
    LibraryProduct("libpetsc", :libpetsc_Float32_Complex_Int32, "$libdir/petsc/single_complex_Int32/lib")
]

dependencies = [
    Dependency("OpenBLAS32_jll"),
    Dependency("MPICH_jll"),
    Dependency("MicrosoftMPI_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9")
