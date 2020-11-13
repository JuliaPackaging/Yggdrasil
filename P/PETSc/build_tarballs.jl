using BinaryBuilder

name = "PETSc"
version = v"3.13.4"

# Collection of sources required to build PETSc. Avoid using the git repository, it will
# require building SOWING which fails in all non-linux platforms.
sources = [
    ArchiveSource("https://www.mcs.anl.gov/petsc/mirror/release-snapshots/petsc-3.13.4.tar.gz",
    "2cf8abd70ec332510b17bff7dc8a465bf1eb053e17e2a0451a4a0256385657d8"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/petsc*
includedir="${prefix}/include"
atomic_patch -p1 $WORKSPACE/srcdir/patches/petsc_name_mangle.patch

BLAS_LAPACK_LIB="${libdir}/libopenblas.${dlext}"

if [[ "${target}" == *-mingw* ]]; then
    #atomic_patch -p1 $WORKSPACE/srcdir/patches/fix-header-cases.patch
    MPI_LIBS="${libdir}/msmpi.${dlext}"
else
    MPI_LIBS="[${libdir}/libmpi.${dlext},libmpifort.${dlext}]"
fi

./configure --prefix=${prefix} \
    CC=${CC} \
    FC=${FC} \
    CXX=${CXX} \
    COPTFLAGS='-O3' \
    CXXOPTFLAGS='-O3' \
    FOPTFLAGS='-O3' \
    --with-64-bit-indices=0 \
    --with-debugging=0 \
    --with-batch \
    --PETSC_ARCH=$target \
    --with-blaslapack-lib=$BLAS_LAPACK_LIB \
    --with-blaslapack-suffix="" \
    --known-64-bit-blas-indices=0 \
    --with-mpi-lib="${MPI_LIBS}" \
    --known-mpi-int64_t=0 \
    --with-mpi-include="${includedir}" \
    --with-sowing=0

if [[ "${target}" == *-mingw* ]]; then
    export CPPFLAGS="-Dpetsc_EXPORTS"
elif [[ "${target}" == powerpc64le-* ]]; then
    export CFLAGS="-fPIC"
    export FFLAGS="-fPIC"
fi

make -j${nproc} \
    PETSC_DIR="${PWD}" \
    PETSC_ARCH="${target}" \
    CPPFLAGS="${CPPFLAGS}" \
    CFLAGS="${CFLAGS}" \
    FFLAGS="${FFLAGS}" \
    DEST_DIR="${prefix}" \
    all

make PETSC_DIR=$PWD PETSC_ARCH=$target DEST_DIR=$prefix install

if [[ "${target}" == *-mingw* ]]; then
    # Move library to ${libdir} on Windows,
    # changing the extension from so to dll.
    mv ${prefix}/lib/libpetsc.so.*.*.* "${libdir}/libpetsc.${dlext}"
    # Remove useless links
    rm ${prefix}/lib/libpetsc.*
fi
"""

# We attempt to build for all defined platforms
platforms = expand_gfortran_versions(supported_platforms(exclude=[Platform("i686", "windows")]))

products = [
    LibraryProduct("libpetsc", :libpetsc),
]

dependencies = [
    Dependency("OpenBLAS32_jll"),
    Dependency("MPICH_jll"),
    Dependency("MicrosoftMPI_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"6")
