using BinaryBuilder

name = "PETSc"
version = v"3.13.0"

# Collection of sources required to build PETSc. Avoid using the git repository, it will
# require building SOWING which fails in all non-linux platforms.
sources = [
    ArchiveSource("https://www.mcs.anl.gov/petsc/mirror/release-snapshots/petsc-3.13.0.tar.gz",
    "df2ff7cb0341bb534a18c7dbea37aa2e2c543a440bf63c24977a605d9b5f8324"),
    DirectorySource(joinpath("/Users/jdlara/cache/Yggdrasil/P/PETSc/","bundled")),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/petsc*
includedir="${prefix}/include"
bindir="${prefix}/include"
atomic_patch -p1 $WORKSPACE/srcdir/patches/petsc_name_mangle.patch

if [[ $nbits == 64 ]] && [[ "$target" != aarch64-* ]]; then
  BLAS_LAPACK_LIB="${libdir}/libopenblas64_.${dlext}"
  BLAS_LAPACK_SUFFIX="_64"
  blas_64=1
else
  BLAS_LAPACK_LIB="${libdir}/libopenblas.${dlext}"
  BLAS_LAPACK_SUFFIX=""
  blas_64=0
fi

if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 $WORKSPACE/srcdir/patches/fix-header-cases.patch
fi

opt_flags="--with-debugging=0 COPTFLAGS='-O3' -CXXOPTFLAGS='-O3' FOPTFLAGS='-O3'"
./configure --prefix=${prefix} $opt_flags \
    CC=$CC \
    FC=$FC \
    CXX=$CXX \
    --with-batch \
    --PETSC_ARCH=$target \
    --with-blaslapack-lib=$BLAS_LAPACK_LIB \
    --with-blaslapack-suffix=$BLAS_LAPACK_SUFFIX \
    --known-64-bit-blas-indices=$blas_64 \
    --with-mpi-lib="${libdir}/libmpi.${dlext}" \
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
platforms = expand_gfortran_versions(supported_platforms())

products = [
    LibraryProduct("libpetsc", :libpetsc),
]

dependencies = [
    Dependency("OpenBLAS_jll"),
    Dependency("MPICH_jll"),
    Dependency("MicrosoftMPI_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"6")
