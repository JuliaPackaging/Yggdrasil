using BinaryBuilder, Pkg

name = "PROPACK"
version = v"0.2.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/optimizers/PROPACK", "08ac329ff8dafc7335d83c209fbd607bc3fe9a5a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/PROPACK/

if [[ "${target}" == *mingw* ]]; then
  LBT="-L${libdir} -lblastrampoline-5"
else
  LBT="-L${libdir} -lblastrampoline"
fi

FFLAGS=(-xf77-cpp-input)
if [[ ${nbits} == 64 ]]; then
  FFLAGS+=(-fdefault-integer-8 -fno-align-commons)

  for sym in caxpy cdotc cdotu ccopy cgemv clarnv clascl cscal csscal daxpy dbdsdc dbdsqr dcopy ddot dgemm dgemv dlamch dlapy2 dlarnv dlartg dlascl dnrm2 dznrm2 drot dscal lsame saxpy sbdsdc sbdsqr scnrm2 scopy sdot sgemm sgemv slamch slapy2 slarnv slartg slascl snrm2 srot sscal zaxpy zcopy zdotc zdotu zdscal zgemv zlarnv zlascl zscal
  do
    FFLAGS+=("-D${sym}=${sym}_64")
  done
fi

FFLAG="${FFLAGS[@]}" 
make SLIB=${dlext} FC="${FC}" FFLAG="${FFLAG}" BLAS="${LBT}"
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

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.9")
