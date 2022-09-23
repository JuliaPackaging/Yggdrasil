# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Exodus"
version = v"0.1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/gsjaardema/seacas.git", "a1da779b061fbdc750f18bcae29295dc5064cb74")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/seacas && export ACCESS=`pwd`
mkdir build
cd build

INSTALL_PATH=${prefix}

GENERATOR=${GENERATOR:-"Unix Makefiles"}

FORTRAN=NO
MPI=NO
SHARED=YES
STATIC=NO
HAVE_NETCDF=YES

CXX=g++
CC=gcc
FC=gfortran
CFLAGS="-Wall -Wunused -pedantic -std=c11"
CXXFLAGS="-Wall -Wunused -pedantic"

THREADSAFE=NO
BUILD_TYPE=RELEASE
DEBUG=OFF

if [ "$OS" == "Darwin" ] ; then
    DARWIN_OPT="-D CMAKE_MACOSX_RPATH:BOOL=ON"
else
    DARWIN_OPT=""
fi

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
-D TPL_ENABLE_Netcdf:BOOL=${HAVE_NETCDF} \
-D TPL_ENABLE_MPI:BOOL=${MPI} \
-D TPL_ENABLE_Pthread:BOOL=${THREADSAFE} \
-D SEACASExodus_ENABLE_THREADSAFE:BOOL=${THREADSAFE} \
${DARWIN_OPT} \
-D MPI_BIN_DIR:PATH=${MPI_BIN} \
-D NetCDF_ROOT:PATH=${prefix} \
-D HDF5_ROOT:PATH=${prefix} \
-D HDF5_NO_SYSTEM_PATHS=YES \
-D PNetCDF_ROOT:PATH=${PNETCDF_PATH} \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
${ACCESS}

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("x86_64", "macOs"),
    Platform("aarch64", "macOs"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows")
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")
