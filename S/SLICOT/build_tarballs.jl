# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase: get_addable_spec

name = "SLICOT"

# NOTE: upstream library version is plain v5.9
# patch number is added here to avoid poisoning the JLL version sequence
version = v"5.9.0"

# Collection of sources required to complete build
# Note to maintainers: extracts from LAPACK are deprecated routines, so probably don't want
# to update the LAPACK version used here (v3.8.0).
sources = [
    GitSource("https://github.com//SLICOT/SLICOT-Reference.git",
              "a037f7eb76134d45e7d222b7f017d5cbd16eb731"),
    GitSource("https://github.com/Reference-LAPACK/lapack.git",
	      "ba3779a6813d84d329b73aac86afc4e041170609"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SLICOT-Reference
echo "cmake_minimum_required(VERSION 3.17)" >>CMakeLists.txt
echo "project( cml )" >>CMakeLists.txt
echo "enable_language( Fortran )" >>CMakeLists.txt
echo "add_subdirectory( src )" >>CMakeLists.txt

cd $WORKSPACE/srcdir/SLICOT-Reference/src
cp ../../lapack/SRC/DEPRECATED/[dz]latzm.f .
cp ../../lapack/SRC/DEPRECATED/dgegs.f .

echo "set( SLICOT_SOURCE_FILES" >source_files.cmake
ls *.f >>source_files.cmake
echo ")" >>source_files.cmake

LAB_SYMBOLS=(
DASUM DAXPY DBDSQR DCABS1 DCOPY DDOT DGEBAK DGEBAL DGEBRD DGECON
DGEEQU DGEES DGEEV DGEGS DGEHRD DGELQ2 DGELQF DGELS DGELSS DGELSY
DGEMM DGEMV DGEQLF DGEQP3 DGEQR2 DGEQRF DGER DGERFS DGERQ2 DGERQF
DGESC2 DGESV DGESVD DGESVX DGETC2 DGETRF DGETRI DGETRS DGGBAK DGGBAL
DGGES DGGEV DHGEQZ DHSEQR DLABAD DLACN2 DLACPY DLADIV DLAEXC DLAG2
DLAGV2 DLAHQR DLAIC1 DLALN2 DLAMC3 DLAMCH DLANGE DLANHS DLANSY DLANTR
DLANV2 DLAPMT DLAPY2 DLAPY3 DLAQGE DLARF DLARFB DLARFG DLARFT DLARFX
DLARNV DLARTG DLAS2 DLASCL DLASET DLASR DLASRT DLASSQ DLASV2 DLASY2
DLATRS DLATZM DNRM2 DORG2R DORGBR DORGHR DORGQR DORGR2 DORGRQ DORM2R
DORMBR DORMHR DORMLQ DORMQL DORMQR DORMR2 DORMRQ DORMRZ DPOCON DPOSV
DPOTRF DPOTRS DPPTRF DPPTRI DPPTRS DPTTRF DPTTRS DROT DROTG DRSCL
DSCAL DSPMV DSPR DSWAP DSYCON DSYEV DSYEVX DSYMM DSYMV DSYR2 DSYR2K
DSYRK DSYSV DSYTRF DSYTRI DSYTRS DTGEX2 DTGEXC DTGSEN DTGSYL DTPMV
DTRCON DTREVC DTREXC DTRMM DTRMV DTRSEN DTRSM DTRSV DTRSYL DTRTRI
DTRTRS DTZRZF DZASUM DZNRM2 IDAMAX ILAENV IZAMAX LSAME XERBLA ZAXPY
ZCOPY ZDRSCL ZDSCAL ZGECON ZGEES ZGEMM ZGEMV ZGEQP3 ZGEQRF ZGESV
ZGESVD ZGETRF ZGETRI ZGETRS ZHGEQZ ZLACGV ZLACON ZLACP2 ZLACPY ZLADIV
ZLAHQR ZLAIC1 ZLANGE ZLANHS ZLANTR ZLAPMT ZLARF ZLARFG ZLARNV ZLARTG
ZLASCL ZLASET ZLASSQ ZLATRS ZLATZM ZROT ZSCAL ZSWAP ZTRSM ZTZRZF
ZUNGQR ZUNMQR ZUNMRQ ZUNMRZ ZGERC ZGERU DGGHRD
ZTRMM ZDOTU ZTREXC ZTRMV ZGERQF ZSTEIN ZGGES
ZGETC2 ZGESC2 ZTGEXC
)


echo "include(source_files.cmake)" >>CMakeLists.txt
echo "add_library( slicot_shared SHARED \${SLICOT_SOURCE_FILES} )" >> CMakeLists.txt
echo "target_link_libraries( slicot_shared \${LAPACK_blas_LIBRARIES})" >> CMakeLists.txt
echo "set_target_properties( slicot_shared PROPERTIES OUTPUT_NAME slicot )" >> CMakeLists.txt
echo "install( TARGETS slicot_shared LIBRARY DESTINATION lib )" >> CMakeLists.txt

FFLAGS="${FFLAGS} -O2 -fPIC -ffixed-line-length-none -cpp"

SYMBOL_DEFS=()
if [[ ${nbits} == 64 ]]; then
  for sym in ${LAB_SYMBOLS[@]}; do
    SYMBOL_DEFS+=("-D${sym}=${sym}_64")
  done
  FFLAGS="${FFLAGS} -fdefault-integer-8 ${SYMBOL_DEFS[@]}"
fi

if [[ "${target}" == *mingw* && ${nbits} == 32 ]]; then
  BLAS_LAPACK="-L${libdir} -lopenblas"
elif [[ "${target}" == *mingw* && ${nbits} == 64 ]]; then
  BLAS_LAPACK="-L${libdir} -lopenblas64_"
else
  BLAS_LAPACK="-L${libdir} -lblastrampoline"
fi

mkdir ../build
cd ../build/
# Above on the fly added CMake code builds shared library with specified LAPACK/BLAS
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DLAPACK_blas_LIBRARIES="${BLAS_LAPACK}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_Fortran_FLAGS="${FFLAGS}" \
    ..
make -j${nproc}
make install

echo "" >>../LICENCE
echo "DGEGS, DLATZM, and ZLATZM are extracted from LAPACK, with the following LICENSE:" >>../LICENCE
echo "" >>../LICENSE
cat ../../lapack/LICENSE >>../LICENSE

install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# Minimal alternative for local sanity checks:
# platforms = [Platform("x86_64","linux";libc="glibc",libgfortran_version="5")]


# The products that we will ensure are always built
products = [
    LibraryProduct("libslicot", :libslicot)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS_jll", uuid="4536629a-c528-5b80-bd46-f80d51c5b363"), platforms=filter(Sys.iswindows, platforms)),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), platforms=filter(!Sys.iswindows, platforms)),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    julia_compat="1.8"
)
