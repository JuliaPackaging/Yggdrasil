using BinaryBuilder

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
platforms = [
    BinaryProvider.Windows(:i686),
    BinaryProvider.Windows(:x86_64),
    BinaryProvider.MacOS(),
    BinaryProvider.Linux(:x86_64, :glibc),
    BinaryProvider.Linux(:i686, :glibc),
    BinaryProvider.Linux(:aarch64, :glibc),
    BinaryProvider.Linux(:armv7l, :glibc),
    BinaryProvider.Linux(:powerpc64le, :glibc),
]


products(prefix) = [
    LibraryProduct(prefix, "libbtf", :libbtf),
    LibraryProduct(prefix, "libsundials_sunlinsolspfgmr", :libsundials_sunlinsolspfgmr),
    LibraryProduct(prefix, "libsundials_ida", :libsundials_ida),
    LibraryProduct(prefix, "libsundials_cvode", :libsundials_cvode),
    LibraryProduct(prefix, "libsundials_cvodes", :libsundials_cvodes),
    LibraryProduct(prefix, "libcolamd", :libcolamd),
    LibraryProduct(prefix, "libsundials_sunmatrixdense", :libsundials_sunmatrixdense),
    LibraryProduct(prefix, "libsundials_sunlinsolspbcgs", :libsundials_sunlinsolspbcgs),
    LibraryProduct(prefix, "libsundials_idas", :libsundials_idas),
    LibraryProduct(prefix, "libsundials_nvecserial", :libsundials_nvecserial),
    LibraryProduct(prefix, "libsundials_sunlinsoldense", :libsundials_sunlinsoldense),
    LibraryProduct(prefix, "libsundials_sunlinsolspgmr", :libsundials_sunlinsolspgmr),
    LibraryProduct(prefix, "libsundials_sunlinsolpcg", :libsundials_sunlinsolpcg),
    LibraryProduct(prefix, "libsundials_sunlinsolsptfqmr", :libsundials_sunlinsolsptfqmr),
    LibraryProduct(prefix, "libsundials_sunlinsolklu", :libsundials_sunlinsolklu),
    LibraryProduct(prefix, "libsundials_sunmatrixsparse", :libsundials_sunmatrixsparse),
    LibraryProduct(prefix, "libsundials_sunlinsolband", :libsundials_sunlinsolband),
    LibraryProduct(prefix, "libsundials_sunmatrixband", :libsundials_sunmatrixband),
    LibraryProduct(prefix, "libsundials_kinsol", :libsundials_kinsol),
    LibraryProduct(prefix, "libsundials_arkode", :libsundials_arkode),
    LibraryProduct(prefix, "libklu", :libklu),
    LibraryProduct(prefix, "libsuitesparseconfig", :libsuitesparseconfig),
    LibraryProduct(prefix, "libamd", :libamd),
]

dependencies = [
    "https://github.com/staticfloat/OpenBLASBuilder/releases/download/v0.2.20-7/build.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, "Sundials", sources, script, platforms, products, dependencies)
