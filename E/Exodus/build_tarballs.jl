# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Exodus"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/gsjaardema/seacas.git", "1452c325ab5d507d000397c713a5b0c4dc57bf81")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/seacas

mkdir build
cd build

### The SEACAS code will install in ${INSTALL_PATH}/bin, ${INSTALL_PATH}/lib, and ${INSTALL_PATH}/include.
INSTALL_PATH=${prefix}

FORTRAN=NO
NETCDF_PATH=${prefix}
PNETCDF_PATH=${prefix}
HDF5_PATH=${prefix}

### Set to ON for parallel compile; otherwise OFF for serial (default)
if [ "${MPI}" = "" ]; then
  netcdf_parallel=$($NETCDF_PATH/bin/nc-config --has-parallel)
  if [ "${netcdf_parallel}" == "yes" ]; then
    MPI=YES
  else
    MPI=NO
  fi
fi

CFLAGS="-Wall -Wunused -pedantic -std=c11"
CXXFLAGS="-Wall -Wunused -pedantic"

GENERATOR="Unix Makefiles"
SHARED="YES"
BUILD_TYPE="RELEASE"

### Set to YES to enable the building of a thread-safe version of the Exodus and IOSS libraries.
THREADSAFE=${THREADSAFE:-NO}

if [ "$THREADSAFE" == "YES" ] ; then
  THREAD_SAFE_OPT="-DSEACASProj_EXTRA_LINK_FLAGS=-lpthread"
fi

function check_enable()
{
  local path=$1
  if [ -e "${path}" ]
  then
    echo "YES"
  else
    echo "NO"
  fi
}

HAVE_NETCDF=$(check_enable "${NETCDF_PATH}/include/netcdf.h")

### Define to NO to *enable* exodus deprecated functions
OMIT_DEPRECATED=${OMIT_DEPRECATED:-NO}

NUMPROCS=${NUMPROCS:-4}

# BUG needs to work with cray too.
if [ "${MPI}" == "YES" ]; then
  if [ "${USE_SRUN}" == "YES" ]
  then
    MPI_EXEC=$(which srun)
    MPI_SYMBOLS="-D MPI_EXEC=${MPI_EXEC} -D MPI_EXEC_NUMPROCS_FLAG=-N  -DMPI_EXEC_DEFAULT_NUMPROCS:STRING=${NUMPROCS} -DMPI_EXEC_MAX_NUMPROCS:STRING=${NUMPROCS}"
    MPI_BIN=$(dirname "${MPI_EXEC}")
  else
    MPI_EXEC=$(which mpiexec)
    MPI_SYMBOLS="-D MPI_EXEC=${MPI_EXEC}  -DMPI_EXEC_DEFAULT_NUMPROCS:STRING=${NUMPROCS} -DMPI_EXEC_MAX_NUMPROCS:STRING=${NUMPROCS}"
    MPI_BIN=$(dirname "${MPI_EXEC}")
  fi
  CXX=mpicxx
  CC=mpicc
  FC=mpif77
fi

### You can add these below if you want more verbosity...
#-D CMAKE_VERBOSE_MAKEFILE:BOOL=ON \
#-D SEACASProj_VERBOSE_CONFIGURE=ON \

### You can add these below to regenerate the flex and bison files for
### aprepro and aprepro_lib May have to touch aprepro.l aprepro.y
### aprepro.ll and aprepro.yy to have them regenerate
#-D GENERATE_FLEX_FILES=ON \
#-D GENERATE_BISON_FILES=ON \

###------------------------------------------------------------------------
cmake -G "${GENERATOR}" \
    -D CMAKE_INSTALL_PREFIX:PATH=${prefix} \
    -D CMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -D CMAKE_CXX_COMPILER:FILEPATH=${CXX} \
    -D CMAKE_C_COMPILER:FILEPATH=${CC} \
    -D CMAKE_Fortran_COMPILER:FILEPATH=${FC} \
    -D CMAKE_CXX_FLAGS="${CXXFLAGS} ${CXX_WARNING_FLAGS}" \
    -D CMAKE_C_FLAGS="${CFLAGS} ${C_WARNING_FLAGS}" \
    -D CMAKE_Fortran_FLAGS="${FFLAGS} ${F77_WARNING_FLAGS}" \
    -D CMAKE_INSTALL_RPATH:PATH=${INSTALL_PATH}/lib \
    -D BUILD_SHARED_LIBS:BOOL=${SHARED} \
    -D CMAKE_BUILD_TYPE=${BUILD_TYPE} \
    -D SEACASProj_ENABLE_SEACASExodus=YES \
    -D SEACASProj_ENABLE_SEACASExodus_for=${FORTRAN} \
    -D SEACASProj_ENABLE_SEACASExoIIv2for32=${FORTRAN} \
    -D SEACASProj_ENABLE_TESTS=YES \
    -D SEACASExodus_ENABLE_STATIC:BOOL=${STATIC} \
    -D SEACASProj_SKIP_FORTRANCINTERFACE_VERIFY_TEST:BOOL=YES \
    -D SEACASProj_HIDE_DEPRECATED_CODE:BOOL=${OMIT_DEPRECATED_CODE} \
    -D SEACASProj_ENABLE_Fortran=${FORTRAN} \
    \
    -D TPL_ENABLE_Netcdf:BOOL=${HAVE_NETCDF} \
    -D TPL_ENABLE_MPI:BOOL=${MPI} \
    -D TPL_ENABLE_Pthread:BOOL=${THREADSAFE} \
    ${THREAD_SAFE_OPT} \
    -D SEACASExodus_ENABLE_THREADSAFE:BOOL=${THREADSAFE} \
    \
    ${MPI_SYMBOLS} \
    \
    -D MPI_BIN_DIR:PATH=${MPI_BIN} \
    -D NetCDF_ROOT:PATH=${NETCDF_PATH} \
    -D HDF5_ROOT:PATH=${HDF5_PATH} \
    -D HDF5_NO_SYSTEM_PATHS=YES \
    -D PNetCDF_ROOT:PATH=${PNETCDF_PATH} \
    \
    ..

echo ""
echo "INSTALL_PATH: ${INSTALL_PATH}"
echo "  "
echo "          CC: ${CC}"
echo "         CXX: ${CXX}"
echo "          FC: ${FC}"
echo "         MPI: ${MPI}"
echo "      SHARED: ${SHARED}"
echo "  BUILD_TYPE: ${BUILD_TYPE}"
echo "  THREADSAFE: ${THREADSAFE}"
echo "  "
echo " HAVE_NETCDF: ${HAVE_NETCDF}"
echo ""

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libexodus", :libexodus)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="NetCDF_jll", uuid="7243133f-43d8-5620-bbf4-c2c921802cf3"))
    Dependency(PackageSpec(name="HDF5_jll", uuid="0234f1f7-429e-5d53-9886-15a909be8d59"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
