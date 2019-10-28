using BinaryBuilder

name = "Sundials"
version = v"3.1.1"

# Collection of sources required to build SundialsBuilder
sources = [
    "https://computation.llnl.gov/projects/sundials/download/sundials-3.1.1.tar.gz" =>
    "a24d643d31ed1f31a25b102a1e1759508ce84b1e4739425ad0e18106ab471a24",
    "http://faculty.cse.tamu.edu/davis/SuiteSparse/SuiteSparse-4.5.3.tar.gz" =>
    "6199a3a35fbce82b155fd2349cf81d2b7cddaf0dac218c08cb172f9bc143f37a",
    "./patches",
]

# Bash recipe for building across all platforms
script = raw"""
# SuiteSparse for KLU
cd $WORKSPACE/srcdir/SuiteSparse*/

# Patches for windows build system
patch -p0 < $WORKSPACE/srcdir/patches/SuiteSparse_windows.patch

for proj in SuiteSparse_config AMD COLAMD BTF KLU; do
    cd $WORKSPACE/srcdir/SuiteSparse/$proj
    make -j${nproc} library
    INSTALL=$WORKSPACE/destdir/ make install
done

echo "KLU Includes"
ls $WORKSPACE/destdir/include
echo "KLU Lib"
ls $WORKSPACE/destdir/lib

# Now the full Sundials build
cd $WORKSPACE/srcdir/sundials-*/
patch -p0 < $WORKSPACE/srcdir/patches/Sundials_windows.patch

# On 64-bit, we need to patch the BLAS libraries to use the Julia name-mangling scheme.
if [[ ${nbits} == 64 ]]; then
    patch -p0 < $WORKSPACE/srcdir/patches/Sundials_ilp64.patch
fi

mkdir build
cd build

CMAKE_FLAGS="-DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}""
CMAKE_FLAGS="${CMAKE_FLAGS} -DCMAKE_BUILD_TYPE=Release -DEXAMPLES_ENABLE_C=OFF"
CMAKE_FLAGS="${CMAKE_FLAGS} -DKLU_ENABLE=ON -DKLU_INCLUDE_DIR=\"$prefix/include/\" -DKLU_LIBRARY_DIR=\"$prefix/lib\""
CMAKE_FLAGS="${CMAKE_FLAGS} -DBLAS_ENABLE=ON"
CMAKE_FLAGS="${CMAKE_FLAGS} -DENABLE_LAPACK=ON -DLAPACK_LIBRARIES=$LIBBLAS"

if [[ ${nbits} == 32 ]]; then
    echo "***   32-bit BUILD   ***"
    LIBBLAS="$prefix/lib/libopenblas.so"
    cmake ${CMAKE_FLAGS} -DBLAS_LIBRARIES=\"$LIBBLAS\" -DSUNDIALS_INDEX_TYPE=int32_t ..
else
    echo "***   64-bit BUILD   ***"
    LIBBLAS="$prefix/lib/libopenblas64_.so"
    cmake ${CMAKE_FLAGS} -DBLAS_LIBRARIES=\"$LIBBLAS\" ..
fi

make -j${nproc}
make install

# On windows, move all `.dll` files to `bin`. We don't want to follow symlinks
# because non-administrative users cannot create symlinks on Windows, so we
# use `cp -L` followed by `rm` instead of just `mv`.
if [[ ${target} == *-mingw32 ]]; then
    cp -L $WORKSPACE/destdir/lib/*.dll $WORKSPACE/destdir/bin
    rm -f $WORKSPACE/destdir/lib/*.dll
fi
"""

# We attempt to build for all defined platforms
platforms = supported_platforms()

products = [
    LibraryProduct("libbtf", :libbtf),
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
    LibraryProduct("libklu", :libklu),
    LibraryProduct("libsuitesparseconfig", :libsuitesparseconfig),
    LibraryProduct("libamd", :libamd),
]

dependencies = [
    "OpenBLAS_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
