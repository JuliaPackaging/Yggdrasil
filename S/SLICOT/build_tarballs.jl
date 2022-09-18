# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using BinaryBuilderBase: get_addable_spec

name = "SLICOT"
version = v"5.8.1"

# Collection of sources required to complete build
# Note to maintainers: extracts from LAPACK are deprecated routines, so probably don't want
# to update the LAPACK version used here.
sources = [
    GitSource("https://github.com//SLICOT/SLICOT-Reference.git",
              "d8e12fe9787f9e7d32df992cc32840e01944abd6"),
    ArchiveSource("https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v3.8.0.tar.gz",
              "deb22cc4a6120bff72621155a9917f485f96ef8319ac074a7afbc68aab88bcf6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SLICOT-Reference
echo "cmake_minimum_required(VERSION 3.17)" >>CMakeLists.txt
echo "project( cml )" >>CMakeLists.txt
echo "enable_language( Fortran )" >>CMakeLists.txt
echo "add_subdirectory( src )" >>CMakeLists.txt

cd $WORKSPACE/srcdir/SLICOT-Reference/src
cp ../../lapack-3.8.0/SRC/DEPRECATED/[dz]latzm.f .
cp ../../lapack-3.8.0/SRC/DEPRECATED/dgegs.f .

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

mkdir ../build
cd ../build/
# Above on the fly added CMake code builds shared library with specified LAPACK/BLAS
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DLAPACK_blas_LIBRARIES="-L${libdir} -lblastrampoline" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_Fortran_FLAGS="${FFLAGS}" \
    ..
make -j${nproc}
make install

echo "" >>../LICENCE
echo "DGEGS, DLATZM, and ZLATZM are extracted from LAPACK, with the following LICENSE:" >>../LICENCE
echo "" >>../LICENSE
cat ../../lapack-3.8.0/LICENSE >>../LICENSE

install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The following was derived from #4770 (Pfapack)
# https://github.com/JuliaPackaging/Yggdrasil/pull/4770
# Since we need to link to libblastrampoline which has seen multiple
# ABI-incompatible versions, we need to expand the julia versions we target
julia_versions = [v"1.7.0", v"1.8.0", v"1.9.0"]
function set_julia_version(platforms::Vector{Platform}, julia_version::VersionNumber)
    _platforms = deepcopy(platforms)
    for p in _platforms
        p["julia_version"] = string(julia_version)
    end
    return _platforms
end
expand_julia_versions(platforms::Vector{Platform}, julia_versions::Vector{VersionNumber}) =
    vcat(set_julia_version.(Ref(platforms), julia_versions)...)
platforms = expand_julia_versions(platforms, julia_versions)

# The products that we will ensure are always built
products = [
    LibraryProduct("libslicot", :libslicot)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(get_addable_spec("libblastrampoline_jll", v"3.0.4+0"); platforms=filter(p -> VersionNumber(p["julia_version"]) == v"1.7.0", platforms)),
    Dependency(get_addable_spec("libblastrampoline_jll", v"5.1.1+1"); platforms=filter(p -> VersionNumber(p["julia_version"]) >= v"1.8.0", platforms)),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.7")
