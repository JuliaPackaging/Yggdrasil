using BinaryBuilder

name = "Sundials"
version = v"3.1.1"

# Collection of sources required to build SundialsBuilder
sources = [
    "https://computation.llnl.gov/projects/sundials/download/sundials-3.1.1.tar.gz" =>
    "a24d643d31ed1f31a25b102a1e1759508ce84b1e4739425ad0e18106ab471a24",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sundials-*/
patch -p0 < $WORKSPACE/srcdir/patches/Sundials_windows.patch

CMAKE_FLAGS="-DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}""
CMAKE_FLAGS="${CMAKE_FLAGS} -DCMAKE_BUILD_TYPE=Release -DEXAMPLES_ENABLE_C=OFF"
CMAKE_FLAGS="${CMAKE_FLAGS} -DKLU_ENABLE=ON -DKLU_INCLUDE_DIR=\"$prefix/include/\" -DKLU_LIBRARY_DIR=\"$prefix/lib\""
CMAKE_FLAGS="${CMAKE_FLAGS} -DBLAS_ENABLE=ON -DENABLE_LAPACK=ON"

if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
    patch -p0 < $WORKSPACE/srcdir/patches/Sundials_ilp64.patch
    BLAS="-lopenblas64_"
else
    CMAKE_FLAGS="${CMAKE_FLAGS} -DSUNDIALS_INDEX_TYPE=int32_t"
    BLAS="-lopenblas"
fi
LAPACK=$BLAS

CMAKE_FLAGS="${CMAKE_FLAGS} -DBLAS_LIBRARIES=$BLAS -DLAPACK_LIBRARIES=$LAPACK"

mkdir build
cd build
cmake ${CMAKE_FLAGS} ..
make -j${nproc}
make install

"""

# We attempt to build for all defined platforms
platforms = supported_platforms()

products = [
    LibraryProduct("libsundials_sunlinsolspfgmr", :libsundials_sunlinsolspfgmr),
    LibraryProduct("libsundials_ida", :libsundials_ida),
    LibraryProduct("libsundials_cvode", :libsundials_cvode),
    LibraryProduct("libsundials_cvodes", :libsundials_cvodes),
    LibraryProduct("libcolamd", :libcolamd),
    LibraryProduct("libsundials_sunmatrixdense", :libsundials_sunmatrixdense),
    LibraryProduct("libsundials_sunlinsolspbcgs", :libsundials_sunlinsolspbcgs),
    LibraryProduct("libsundials_idas", :libsundials_idas),
    LibraryProduct("libsundials_nvecserial", :libsundials_nvecserial),
    LibraryProduct("libsundials_sunlinsoldense", :libsundials_sunlinsoldense),
    LibraryProduct("libsundials_sunlinsolspgmr", :libsundials_sunlinsolspgmr),
    LibraryProduct("libsundials_sunlinsolpcg", :libsundials_sunlinsolpcg),
    LibraryProduct("libsundials_sunlinsolsptfqmr", :libsundials_sunlinsolsptfqmr),
    LibraryProduct("libsundials_sunlinsolklu", :libsundials_sunlinsolklu),
    LibraryProduct("libsundials_sunmatrixsparse", :libsundials_sunmatrixsparse),
    LibraryProduct("libsundials_sunlinsolband", :libsundials_sunlinsolband),
    LibraryProduct("libsundials_sunmatrixband", :libsundials_sunmatrixband),
    LibraryProduct("libsundials_kinsol", :libsundials_kinsol),
    LibraryProduct("libsundials_arkode", :libsundials_arkode),
]

dependencies = [
    "OpenBLAS_jll",
    "SuiteSparse_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
