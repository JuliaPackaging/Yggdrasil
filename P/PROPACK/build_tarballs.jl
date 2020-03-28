using BinaryBuilder

name = "PROPACK"
version = v"0.1"

sources = [
    ArchiveSource("https://github.com/optimizers/PROPACK/archive/v1.0.tar.gz",
                  "0d029a4c2cdcdb9b18a4fae77593a562f79406c3f79839ee948782b37974a10e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/PROPACK-*/

OPENBLAS="-lopenblas"
FFLAGS=(-xf77-cpp-input)
if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
  OPENBLAS="-lopenblas64_"
  FFLAGS+=(-fdefault-integer-8 -fno-align-commons)

  for sym in caxpy cdotc cdotu ccopy cgemv clarnv clascl cscal csscal daxpy dbdsdc dbdsqr dcopy ddot dgemm dgemv dlamch dlapy2 dlarnv dlartg dlascl dnrm2 dznrm2 drot dscal lsame saxpy sbdsdc sbdsqr scnrm2 scopy sdot sgemm sgemv slamch slapy2 slarnv slartg slascl snrm2 srot sscal zaxpy zcopy zdotc zdotu zdscal zgemv zlarnv zlascl zscal
  do
    FFLAGS+=("-D${sym}=${sym}_64")
  done
fi

make SLIB=${dlext} FFLAG=\"${FFLAGS[*]}\" BLAS=${OPENBLAS}
cp complex8/libcpropack.${dlext} complex16/libzpropack.${dlext} single/libspropack.${dlext} double/libdpropack.${dlext} ${libdir}/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

platforms = expand_gfortran_versions(platforms)

products = [
    LibraryProduct("libcpropack", :libcpropack),
    LibraryProduct("libzpropack", :libzpropack),
    LibraryProduct("libspropack", :libspropack),
    LibraryProduct("libdpropack", :libdpropack),
]

dependencies = [
    Dependency("OpenBLAS_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
