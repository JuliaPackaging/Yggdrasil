using BinaryBuilder

name = "SuiteSparse"
version = v"5.4.0"

# Collection of sources required to build SuiteSparse
sources = [
    "http://faculty.cse.tamu.edu/davis/SuiteSparse/SuiteSparse-$(version).tar.gz" =>
    "374dd136696c653e34ef3212dc8ab5b61d9a67a6791d5ec4841efb838e94dbd1",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SuiteSparse/

# Apply Jameson's shlib patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/SuiteSparse-shlib.patch

# Disable OpenMP as it will probably interfere with blas threads and Julia threads
FLAGS=(INSTALL="${prefix}" INSTALL_LIB="${libdir}" INSTALL_INCLUDE="${prefix}/include" CFOPENMP=)

if [[ ${target} == *mingw32* ]]; then
    FLAGS+=(UNAME=Windows)
    FLAGS+=(LDFLAGS="${LDFLAGS} -L${libdir} -shared")
else
    FLAGS+=(UNAME="$(uname)")
    FLAGS+=(LDFLAGS="${LDFLAGS} -L${libdir}")
fi

if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
    SUN="-DSUN64 -DLONGBLAS='long long'"

    FLAGS+=(BLAS="-lopenblas64_" LAPACK="-lopenblas64_")
    FLAGS+=(UMFPACK_CONFIG="$SUN" CHOLMOD_CONFIG="$SUN -DNPARTITION" SPQR_CONFIG="$SUN")
else
    FLAGS+=(BLAS="-lopenblas" LAPACK="-lopenblas")
    FLAGS+=(CHOLMOD_CONFIG="-DNPARTITION")
fi

make -j${nproc} -C SuiteSparse_config "${FLAGS[@]}" library config

for proj in SuiteSparse_config AMD BTF CAMD CCOLAMD COLAMD CHOLMOD LDL KLU UMFPACK RBio SPQR; do
    make -j${nproc} -C $proj "${FLAGS[@]}" library CFOPENMP="$CFOPENMP"
    make -j${nproc} -C $proj "${FLAGS[@]}" install CFOPENMP="$CFOPENMP"
done

# For now, we'll have to adjust the name of the OpenBLAS library on macOS.
# Eventually, this should be fixed upstream
if [[ ${target} == "*-apple-*" ]]; then
    echo "-- Modifying library name for OpenBLAS"

    for nm in libcholmod.3.0.13 libspqr.2.0.9 libumfpack.5.7.8; do
        # Figure out what version it probably latched on to:
        OPENBLAS_LINK=$(otool -L ${libdir}/${nm}.dylib | grep libopenblas64_ | awk '{ print $1 }')
        install_name_tool -change ${OPENBLAS_LINK} @rpath/libopenblas64_.dylib ${libdir}/${nm}.dylib
    done
fi

# Compile suitesparse_wrapper shim
cd $WORKSPACE/srcdir/SuiteSparse_wrapper
make "${FLAGS[@]}" install

install_license ${WORKSPACE}/srcdir/SuiteSparse/LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsuitesparseconfig",   :libsuitesparseconfig),
    LibraryProduct("libamd",                 :libamd),
    LibraryProduct("libbtf",                 :libbtf),
    LibraryProduct("libcamd",                :libcamd),
    LibraryProduct("libccolamd",             :libccolamd),
    LibraryProduct("libcolamd",              :libcolamd),
    LibraryProduct("libcholmod",             :libcholmod),
    LibraryProduct("libldl",                 :libldl),
    LibraryProduct("libklu",                 :libklu),
    LibraryProduct("libumfpack",             :libumfpack),
    LibraryProduct("librbio",                :librbio),
    LibraryProduct("libspqr",                :libspqr),
    LibraryProduct("libsuitesparse_wrapper", :libsuitesparse_wrapper),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "OpenBLAS_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
