# Build script for Armadillo: C++ library for linear algebra.  It contains a
# library libarmadillo.so that is a wrapper for OpenBLAS, and header files.

using BinaryBuilder


name = "armadillo"
version = v"12.8.3"
sources = [
    ArchiveSource("http://sourceforge.net/projects/arma/files/armadillo-$(version).tar.xz",
                  "2922589f6387796504b340da6bb954bef3d87574c298515893289edd2d890151")
]

script = raw"""
cd ${WORKSPACE}/srcdir/armadillo-*/
mkdir build && cd build

FLAGS=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
       -DCMAKE_INSTALL_PREFIX=${prefix}
       -DCMAKE_BUILD_TYPE=Release
       -DBUILD_SHARED_LIBS=ON)

if [[ "${nbits}" == 64 ]]; then
    FLAGS+=(-Dopenblas_LIBRARY="${libdir}/libopenblas64_.${dlext}")
    # Force Armadillo's CMake configuration to accept OpenBLAS as a LAPACK
    # replacement.
    FLAGS+=(-DLAPACK_LIBRARY="${libdir}/libopenblas64_.${dlext}")

    SYMB_DEFS=()
    for sym in sasum dasum snrm2 dnrm2 sdot ddot sgemv dgemv cgemv zgemv sgemm dgemm cgemm zgemm ssyrk dsyrk cherk zherk; do
        SYMB_DEFS+=("-D${sym}=${sym}_64")
    done
    if [[ "${target}" == *-apple-* ]] || [[ "${target}" == *-mingw* ]]; then
        FLAGS+=(-DALLOW_OPENBLAS_MACOS=ON)
    fi

    for sym in cgbcon cgbsv cgbsvx cgbtrf cgbtrs cgecon cgees cgeev cgeevx cgehrd cgels cgelsd cgemm cgemv cgeqp3 cgeqrf cgesdd cgesv cgesvd cgesvx cgetrf cgetri cgetrs cgges cggev cgtsv cgtsvx cheev cheevd cherk clangb clange clanhe clansy cpbtrf cpocon cposv cposvx cpotrf cpotri cpotrs cpstrf ctrcon ctrsyl ctrtri ctrtrs cungqr dasum ddot dgbcon dgbsv dgbsvx dgbtrf dgbtrs dgecon dgees dgeev dgeevx dgehrd dgels dgelsd dgemm dgemv dgeqp3 dgeqrf dgesdd dgesv dgesvd dgesvx dgetrf dgetri dgetrs dgges dggev dgtsv dgtsvx dlahqr dlangb dlange dlansy dlarnv dnrm2 dorgqr dpbtrf dpocon dposv dposvx dpotrf dpotri dpotrs dpstrf dstedc dsyev dsyevd dsyrk dtrcon dtrevc dtrsyl dtrtri dtrtrs ilaenv sasum sdot sgbcon sgbsv sgbsvx sgbtrf sgbtrs sgecon sgees sgeev sgeevx sgehrd sgels sgelsd sgemm sgemv sgeqrf sgeqp3 sgesdd sgesv sgesvd sgesvx sgetrf sgetri sgetrs sgges sggev sgtsv sgtsvx slahqr slangb slange slansy slarnv snrm2 sorgqr spbtrf spocon sposv sposvx spotrf spotri spotrs spstrf sstedc ssyev ssyevd ssyrk strcon strevc strsyl strtri strtrs zgbcon zgbsv zgbsvx zgbtrf zgbtrs zgecon zgees zgeev zgeevx zgehrd zgels zgelsd zgemm zgemv zgeqp3 zgeqrf zgesdd zgesv zgesvd zgesvx zgetrf zgetri zgetrs zgges zggev zgtsv zgtsvx zheev zheevd zherk zlangb zlange zlanhe zlansy zpbtrf zpocon zposv zposvx zpotrf zpotri zpotrs zpstrf ztrcon ztrsyl ztrtri ztrtrs zungqr; do
        SYMB_DEFS+=("-D${sym}=${sym}_64")
    done

    export CXXFLAGS="${SYMB_DEFS[@]}"

    # Force the configuration parameter ARMA_BLAS_LONG to be true, as in our
    # setting 64-bit systems are going to need a 64-bit integer to be used for
    # Armadillo's `blas_int` type.
    sed -i 's|// #define ARMA_BLAS_LONG$|#define ARMA_BLAS_LONG|' ../include/armadillo_bits/config.hpp.cmake
    cat ../include/armadillo_bits/config.hpp.cmake
else
    # Force Armadillo's CMake configuration to accept OpenBLAS as a LAPACK
    # replacement.
    FLAGS+=(-DLAPACK_LIBRARY="${libdir}/libopenblas.${dlext}")
fi

cmake .. "${FLAGS[@]}"
make -j${nproc}
make install

# Armadillo links against a _very_ specific version of OpenBLAS on macOS by
# default:
if [[ ${target} == *apple* ]]; then
    # Figure out what version it probably latched on to:
    OPENBLAS_LINK=$(otool -L ${libdir}/libarmadillo.dylib | grep libopenblas64_ | awk '{ print $1 }')
    install_name_tool -change ${OPENBLAS_LINK} @rpath/libopenblas64_.dylib ${libdir}/libarmadillo.dylib
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = supported_platforms()

# The products that we will ensure are always built.
products = [
    LibraryProduct("libarmadillo", :libarmadillo)
]

# Dependencies that must be installed before this package can be built.
dependencies = [
    Dependency("OpenBLAS_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6", julia_compat="1.7")
