# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TopOpt_in_PETSc"
version = v"0.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.mcs.anl.gov/petsc/mirror/release-snapshots/petsc-3.15.2.tar.gz",
    "3b10c19c69fc42e01a38132668724a01f1da56f5c353105cd28f1120cc9041d8"),
    GitSource("https://github.com/topopt/TopOpt_in_PETSc", "26eecbf3b1d0135956e0364d77c30e43e9bc3db2"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
# New makefiles added, the patches fix some weird include issues mostly.
# There is likely a better way to fix them, or upstream the fixes.
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

build_petsc()
{

    if [[ "${3}" == "Int64" ]]; then
        USE_INT64=1
    else
        USE_INT64=0
    fi

    ./configure --prefix=${prefix} \
        CC=${CC} \
        FC=${FC} \
        CXX=${CXX} \
        COPTFLAGS='-O3' \
        CXXOPTFLAGS='-O3' \
        CFLAGS='-fno-stack-protector' \
        FOPTFLAGS='-O3' \
        --with-64-bit-indices=${USE_INT64} \
        --with-debugging=0 \
        --with-batch \
        --PETSC_ARCH=${target}_${1}_${2}_${3} \
        --with-blaslapack-lib=$BLAS_LAPACK_LIB \
        --with-blaslapack-suffix="" \
        --known-64-bit-blas-indices=0 \
        --with-mpi-lib="${MPI_LIBS}" \
        --known-mpi-int64_t=0 \
        --with-mpi-include="${includedir}" \
        --with-sowing=0 \
        --with-precision=${1} \
        --with-scalar-type=${2}

    if [[ "${target}" == *-mingw* ]]; then
        export CPPFLAGS="-Dpetsc_EXPORTS"
    elif [[ "${target}" == powerpc64le-* ]]; then
        export CFLAGS="-fPIC"
        export FFLAGS="-fPIC"
    fi

    make -j${nproc} \
        PETSC_DIR="${PWD}" \
        PETSC_ARCH="${target}_${1}_${2}_${3}" \
        CPPFLAGS="${CPPFLAGS}" \
        CFLAGS="${CFLAGS}" \
        FFLAGS="${FFLAGS}" \
        DEST_DIR="${prefix}" \
        all

    make PETSC_DIR=$PWD PETSC_ARCH=${target}_${1}_${2}_${3} DEST_DIR=$prefix install
}

build_petsc double real Int32

cd ../TopOpt_in_PETSc
cp ../Makefile Makefile
make topopt
cp topopt ${bindir}/topopt
make libtopopt
cp libtopopt.$dlext ${libdir}/libtopopt.$dlext
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms(exclude=[Platform("i686", "windows")]))


# The products that we will ensure are always built
products = [
    LibraryProduct("libtopopt", :libtopopt),
    ExecutableProduct("topopt", :topopt)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenBLAS32_jll"),
    Dependency("MPICH_jll"),
    Dependency("MicrosoftMPI_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"9")
