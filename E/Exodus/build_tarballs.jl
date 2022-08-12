# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Exodus"
version = v"0.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/gsjaardema/seacas.git", "a1da779b061fbdc750f18bcae29295dc5064cb74")
]

# Bash recipe for building across all platforms
script = raw"""
#! /usr/bin/env bash

cd $WORKSPACE/srcdir/seacas

mkdir build
cd build

INSTALL_PATH=${prefix}
FORTRAN=NO
NETCDF_PATH=${prefix}
PNETCDF_PATH=${prefix}
HDF5_PATH=${prefix}

# CMake config file to build ONLY the exodus libraries (C, Fortran, Fortran-32, and Python interface)
# By default, Will build both static and shared version of the C API.
# If only want shared, then run with "sh STATIC=NO ../cmake-exodus"

EXTRA_ARGS=$@

### The following assumes you are building in a subdirectory of ACCESS Root
### If not, then define "ACCESS" to point to the root of the SEACAS source code.
if [ "$ACCESS" == "" ]
then
    ACCESS=$(cd ..; pwd)
fi

### The SEACAS code will install in ${INSTALL_PATH}/bin, ${INSTALL_PATH}/lib, and ${INSTALL_PATH}/include.
INSTALL_PATH=${INSTALL_PATH:-${ACCESS}}

function check_valid()
{
    if [ "${!1}" == "YES" ] || [ "${!1}" == "ON" ]; then
	echo "YES"
	return 1
    fi
    if [ "${!1}" == "NO" ] || [ "${!1}" == "OFF" ]; then
	echo "NO"
	return 1
    fi
    echo "Invalid value for $1 (${!1}) -- Must be ON, YES, NO, or OFF"
    exit 1
}

#FORTRAN=${FORTRAN:-YES}
#FORTRAN=${FORTRAN:-NO}
#FORTRAN=$(check_valid FORTRAN)

### TPLs --
### Make sure these point to the locations to find the libraries and includes in lib and include
### subdirectories of the specified paths.
### For example, netcdf.h should be in ${NETCDF_PATH}/include
#NETCDF_PATH=${NETCDF_PATH:-${INSTALL_PATH}}
#PNETCDF_PATH=${PNETCDF_PATH:-${INSTALL_PATH}}
#HDF5_PATH=${HDF5_PATH:-${INSTALL_PATH}}

### Set to ON for parallel compile; otherwise OFF for serial (default)
if [ "${MPI}" = "" ]
then
  netcdf_parallel=$($NETCDF_PATH/bin/nc-config --has-parallel)
  if [ "${netcdf_parallel}" == "yes" ]
  then
      MPI=YES
  else
      MPI=NO
  fi
fi

#MPI=$(check_valid MPI)
echo "${txtgrn}MPI set to ${MPI}${txtrst}"

if [ "${MPI}" == "NO" ]
then
  ### Change this to point to the compilers you want to use
  ## Some builds set this to EXTERNAL to set CXX, CC, and FC externally.
  COMPILER=${COMPILER:-gnu}

  if [ "$COMPILER" == "gnu" ]
  then
      CXX=g++
      CC=gcc
      FC=gfortran
      CFLAGS="-Wall -Wunused -pedantic -std=c11"
      CXXFLAGS="-Wall -Wunused -pedantic"
  fi

  if [ "$COMPILER" == "gnubrew" ]
  then
      VER=${VER:-10}
      CXX=g++-${VER}
      CC=gcc-${VER}
      FC=gfortran-${VER}
      CFLAGS="-Wall -Wunused -pedantic -std=c11"
      CXXFLAGS="-Wall -Wunused -pedantic"
  fi

  if [ "$COMPILER" == "gnumacport" ]
  then
      VER=${VER:-10}
      CXX=g++-mp-${VER}
      CC=gcc-mp-${VER}
      FC=gfortran-mp-${VER}
      CFLAGS="-Wall -Wunused -pedantic -std=c11"
      CXXFLAGS="-Wall -Wunused -pedantic"
  fi

  if [ "$COMPILER" == "clangmacport" ]
  then
      VER=${VER:-9}
      CXX=clang++-mp-${VER}.0
      CC=clang-mp-${VER}.0
      FC=gfortran
      CFLAGS="-Wall -Wunused -pedantic -std=c11"
      CXXFLAGS="-Wall -Wunused -pedantic"
  fi

  if [ "$COMPILER" == "nvidia" ]
  then
      CXX="nvcc -x c++"
      CC=nvcc
      FC=gfortran
  fi

  if [ "$COMPILER" == "clang" ]
  then
      CXX=clang++
      CC=clang
      FC=${FC:-gfortran}
      CFLAGS="-Wall -Wunused -pedantic"
      CXXFLAGS="-Wall -Wunused -pedantic"
  fi

  if [ "$COMPILER" == "intel" ]
  then
      CXX=icpc
      CC=icc
      FC=ifort
      CFLAGS="-Wall -Wunused"
      CXXFLAGS="-Wall -Wunused"
  fi

  # When building:  "scan-build make -j8"
  if [ "$COMPILER" == "analyzer" ]
  then
      CXX=/opt/local/libexec/llvm-9.0/libexec/c++-analyzer
      CC=/opt/local/libexec/llvm-9.0/libexec/ccc-analyzer
      FC=gfortran
      CFLAGS="-Wall -Wunused"
      CXXFLAGS="-Wall -Wunused"
      FORTRAN="NO"
  fi

  if [ "$COMPILER" == "ibm" ]
  then
      CXX=xlC
      CC=xlc
      FC=xlf
  fi
fi

GENERATOR=${GENERATOR:-"Unix Makefiles"}

CRAY="${CRAY:-NO}"
CRAY=$(check_valid CRAY)

if [ "${CRAY}" == "YES" ]
then
    SHARED="${SHARED:-NO}"
else
    SHARED="${SHARED:-YES}"
fi
SHARED=$(check_valid SHARED)

if [ "${CRAY}" == "YES" ] && [ "${SHARED}" == "NO" ]
then
  # Assumes we build our own static zlib with CRAY
  EXTRA_LIB=-DSeacas_EXTRA_LINK_FLAGS=${INSTALL_PATH}/lib/libz.a
fi

### Switch for Debug or Release build:
### Check that both `DEBUG` and `BUILD_TYPE` are not set
if [ ! -z ${DEBUG+x} ] && [ ! -z ${BUILD_TYPE+x} ]
then
    echo "ERROR: Both DEBUG and BUILD_TYPE are set. Only one is allowed."
    exit
fi

BUILD_TYPE="${BUILD_TYPE:-RELEASE}"

if [ ! -z ${DEBUG+x} ]
then
    if [ "${DEBUG}" == "ON" ] || [ "${DEBUG}" == "YES" ]
    then
	BUILD_TYPE="DEBUG"
    elif [ "${DEBUG}" == "OFF" ] || [ "${DEBUG}" == "NO" ]
    then
	BUILD_TYPE="RELEASE"
    else
	echo "ERROR: Invalid value for DEBUG ('$DEBUG'). Must be 'ON', 'OFF', 'YES', 'NO'."
	exit
    fi
fi


### Set to YES to enable the building of a thread-safe version of the Exodus and IOSS libraries.
THREADSAFE=${THREADSAFE:-NO}
THREADSAFE=$(check_valid THREADSAFE)

if [ "$THREADSAFE" == "YES" ] ; then
  THREAD_SAFE_OPT="-DTPL_Pthread_LIBRARIES=-lpthread"
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

### DataWarp (Burst Buffer)
### I use the following for mutrino (10/16/2018):
###    module load datawarp
###    -D TPL_ENABLE_DataWarp:BOOL=ON \
###    -D DataWarp_LIBRARY_DIRS:PATH=/opt/cray/datawarp/2.1.16-6.0.5.1_2.61__g238b34d.ari/lib \
###    -D DataWarp_INCLUDE_DIRS:PATH=/opt/cray/datawarp/2.1.16-6.0.5.1_2.61__g238b34d.ari/include \

### Define to NO to *enable* exodus deprecated functions
OMIT_DEPRECATED=${OMIT_DEPRECATED:-YES}

NUMPROCS=${NUMPROCS:-4}

# BUG needs to work with cray too.
if [ "${MPI}" == "YES" ] && [ "${CRAY}" == "YES" ]
then
   MPI_EXEC=$(which srun)
   MPI_SYMBOLS="-D MPI_EXEC=${MPI_EXEC} -D MPI_EXEC_NUMPROCS_FLAG=-n  -DMPI_EXEC_DEFAULT_NUMPROCS:STRING=${NUMPROCS} -DMPI_EXEC_MAX_NUMPROCS:STRING=${NUMPROCS}"
   CXX=CC
   CC=cc
   FC=ftn
   MPI_BIN=$(dirname $(which ${CC}))
elif [ "${MPI}" == "YES" ]
then
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

OS=$(uname -s)
if [ "$SHARED" == "YES" ]
then
    if [ "$OS" == "Darwin" ] ; then
	LD_EXT="dylib"
    else
	LD_EXT="so"
    fi
else
    EXTRA_LIB="-DSeacas_EXTRA_LINK_FLAGS=z;dl -DSEACASExodus_ENABLE_SHARED:BOOL=OFF"
    LD_EXT="a"
fi

if [ "$OS" == "Darwin" ] ; then
  DARWIN_OPT="-D CMAKE_MACOSX_RPATH:BOOL=ON"
else
  DARWIN_OPT=""
fi

FC=${FC:-gfortran}

EXTRA_WARNINGS=${EXTRA_WARNINGS:-NO}
EXTRA_WARNINGS=$(check_valid EXTRA_WARNINGS)

SANITIZER=${SANITIZER:-NO}

if [ "$SANITIZER" != "NO" ] ; then
### To use the clang sanitizers:
#sanitizer=address     #: AddressSanitizer, a memory error detector.
#sanitizer=integer     #: Enables checks for undefined or suspicious integer behavior.
#sanitizer=thread      #: ThreadSanitizer, a data race detector.
#sanitizer=memory      #: MemorySanitizer, experimental detector of uninitialized reads.
#sanitizer=undefined   #: Fast and compatible undefined behavior checker.
#sanitizer=dataflow    #: DataFlowSanitizer, a general data flow analysis.
#sanitizer=cfi         #: control flow integrity checks. Requires -flto.
#sanitizer=safe-stack  #: safe stack protection against stack-based memory corruption errors.
SANITIZE="-fsanitize=${SANITIZER} -fno-omit-frame-pointer -fPIC"
if [ "$SANITIZER" == "integer" ] ; then
  SANITIZE="$SANITIZE -fno-sanitize=unsigned-integer-overflow"
fi
fi

### You can add these below if you want more verbosity...
#-D CMAKE_VERBOSE_MAKEFILE:BOOL=ON \
#-D Seacas_VERBOSE_CONFIGURE=ON \

### You can add these below to regenerate the flex and bison files for
### aprepro and aprepro_lib May have to touch aprepro.l aprepro.y
### aprepro.ll and aprepro.yy to have them regenerate
#-D GENERATE_FLEX_FILES=ON \
#-D GENERATE_BISON_FILES=ON \

if [ "${EXTRA_WARNINGS}" == "YES" ]; then
### Additional gcc warnings:
if [ "$COMPILER" == "gnu" ]
then
  COMMON_WARNING_FLAGS="\
   -Wshadow -Wabsolute-value -Waddress -Waliasing -Wpedantic\
  "

  C_WARNING_FLAGS="${COMMON_WARNING_FLAGS}"

  CXX_WARNING_FLAGS="${COMMON_WARNING_FLAGS} -Wnull-dereference -Wzero-as-null-pointer-constant -Wuseless-cast -Weffc++ -Wsuggest-override"

  # -Wuseless-cast
  # -Wold-style-cast
  # -Wdouble-promotion
fi
if [ "$COMPILER" == "clang" ]
then
  C_WARNING_FLAGS="-Weverything -Wno-missing-prototypes -Wno-sign-conversion -Wno-reserved-id-macro"

  CXX_WARNING_FLAGS="-Weverything -Wno-c++98-compat -Wno-old-style-cast -Wno-sign-conversion -Wno-reserved-id-macro"
fi
fi

rm -f CMakeCache.txt
###------------------------------------------------------------------------
cmake -G "${GENERATOR}" \
-D CMAKE_CXX_COMPILER:FILEPATH=${CXX} \
-D CMAKE_C_COMPILER:FILEPATH=${CC} \
-D CMAKE_Fortran_COMPILER:FILEPATH=${FC} \
-D CMAKE_CXX_FLAGS="${CXXFLAGS} ${CXX_WARNING_FLAGS} ${SANITIZE}" \
-D CMAKE_C_FLAGS="${CFLAGS} ${C_WARNING_FLAGS} ${SANITIZE}" \
-D CMAKE_Fortran_FLAGS="${FFLAGS} ${F77_WARNING_FLAGS} ${SANITIZE}" \
-D Seacas_ENABLE_STRONG_C_COMPILE_WARNINGS=${EXTRA_WARNINGS} \
-D Seacas_ENABLE_STRONG_CXX_COMPILE_WARNINGS=${EXTRA_WARNINGS} \
-D CMAKE_INSTALL_RPATH:PATH=${INSTALL_PATH}/lib \
-D BUILD_SHARED_LIBS:BOOL=${SHARED} \
-D CMAKE_BUILD_TYPE=${BUILD_TYPE} \
-D Seacas_ENABLE_SEACASExodus=YES \
-D Seacas_ENABLE_SEACASExodus_for=${FORTRAN} \
-D Seacas_ENABLE_SEACASExoIIv2for32=${FORTRAN} \
-D Seacas_ENABLE_TESTS=YES \
-D SEACASExodus_ENABLE_STATIC:BOOL=${STATIC} \
-D CMAKE_INSTALL_PREFIX:PATH=${INSTALL_PATH} \
-D Seacas_SKIP_FORTRANCINTERFACE_VERIFY_TEST:BOOL=YES \
-D Seacas_HIDE_DEPRECATED_CODE:BOOL=${OMIT_DEPRECATED_CODE} \
-D Seacas_ENABLE_Fortran=${FORTRAN} \
${EXTRA_LIB} \
\
-D TPL_ENABLE_Netcdf:BOOL=${HAVE_NETCDF} \
-D TPL_ENABLE_MPI:BOOL=${MPI} \
-D TPL_ENABLE_Pthread:BOOL=${THREADSAFE} \
${THREAD_SAFE_OPT} \
-D SEACASExodus_ENABLE_THREADSAFE:BOOL=${THREADSAFE} \
\
${MPI_SYMBOLS} \
${DARWIN_OPT} \
\
-D MPI_BIN_DIR:PATH=${MPI_BIN} \
-D NetCDF_ROOT:PATH=${NETCDF_PATH} \
-D HDF5_ROOT:PATH=${HDF5_PATH} \
-D HDF5_NO_SYSTEM_PATHS=YES \
-D PNetCDF_ROOT:PATH=${PNETCDF_PATH} \
\
$EXTRA_ARGS \
${ACCESS}

echo ""
echo "                  OS: ${OS}"
echo "              ACCESS: ${ACCESS}"
echo "        INSTALL_PATH: ${INSTALL_PATH}"
echo "  "
echo "                  CC: ${CC}"
echo "                 CXX: ${CXX}"
echo "                  FC: ${FC}"
echo "                 MPI: ${MPI}"
echo "              SHARED: ${SHARED}"
echo "          BUILD_TYPE: ${BUILD_TYPE}"
echo "          THREADSAFE: ${THREADSAFE}"
echo "OMIT_DEPRECATED_CODE: ${OMIT_DEPRECATED_CODE}"
echo "                CRAY: ${CRAY}"
echo "  "
echo "         HAVE_NETCDF: ${HAVE_NETCDF}"
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.7")
