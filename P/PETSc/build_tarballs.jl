using BinaryBuilder

name = "PETSc"
version = v"3.13.0"

# Collection of sources required to build Sundials
sources = [
    GitSource("https://gitlab.com/petsc/petsc.git",
              "a826417c4d3aef8d40f916498c49a8f0d4fade93"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/petsc*
libinclude="/workspace/destdir/include"
atomic_patch -p1 $WORKSPACE/srcdir/patches/petsc_name_mangle.patch

if [[ $nbits == 64 ]] && [[ "$target" != aarch64-* ]]; then
  BLAS_LAPACK_LIB="${libdir}/libopenblas64_.${dlext}"
  BLAS_LAPACK_SUFFIX="_64_"
  blas_64=1
else
  BLAS_LAPACK_LIB="${libdir}/libopenblas.${dlext}"
  BLAS_LAPACK_SUFFIX=""
  blas_64=0
fi

opt_flags="--with-debugging=0 COPTFLAGS='-O3 -march=native -mtune=native' -CXXOPTFLAGS='-O3 -march=native -mtune=native' FOPTFLAGS='-O3 -march=native -mtune=native"
./configure $opt_flags CC=$CC FC=$FC CXX=$CXX --with-batch --PETSC_ARCH=$BUILD_AR  --with-blaslapack-lib=$BLAS_LAPACK_LIB --with-blaslapack-suffix=$BLAS_LAPACK_SUFFIX --known-64-bit-blas-indices=$blas_64 --with-mpi=0

# Generates some errors when mpi is included. These flags detect it properly
# --with-mpi-lib="${libdir}/libmpi.${dlext}" --with-mpi-include="$includedir"

make PETSC_DIR=$(pwd()) PETSC_ARCH=$BUILD_AR

# Move libraries to ${libdir} on Windows
if [[ "${target}" == *-mingw* ]]; then
    mv ${prefix}/lib/libpetsc*.${dlext} "${libdir}"
fi
"""

# We attempt to build for all defined platforms
platforms = expand_gfortran_versions(supported_platforms())

products = [
    LibraryProduct("libpetsc", :libsundials_arkode),
]

dependencies = [
    Dependency("OpenBLAS_jll"),
    Dependency("MPICH_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"6")
