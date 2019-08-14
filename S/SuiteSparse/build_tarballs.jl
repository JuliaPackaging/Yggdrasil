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

FLAGS=(INSTALL="${prefix}")

if [[ ${target} == *mingw32* ]]; then
    FLAGS+=(UNAME=Windows)
    FLAGS+=(LDFLAGS="${LDFLAGS} -L${prefix}/lib -shared")
    FLAGS+=(CFOPENMP=)
else
    FLAGS+=(UNAME="$(uname)")
    FLAGS+=(LDFLAGS="${LDFLAGS} -L${prefix}/lib")
fi

# Switch `ar` usage on OSX
if [[ ${target} == "x86_64-apple-darwin14" ]]; then
    export AR=/opt/${target}/bin/${target}-ar
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
if [[ ${target} == "x86_64-apple-darwin14" ]]; then
    echo "-- Modifying library name for OpenBLAS"

    for nm in libcholmod.3.0.13 libspqr.2.0.9 libumfpack.5.7.8; do
        install_name_tool -change libopenblas64_.0.3.3.dylib @rpath/libopenblas64_.dylib ${prefix}/lib/${nm}.dylib
    done
fi

# Compile suitesparse_wrapper shim
cd $WORKSPACE/srcdir/SuiteSparse_wrapper
make "${FLAGS[@]}" install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gcc_versions(supported_platforms())

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libsuitesparseconfig",   :libsuitesparseconfig),
    LibraryProduct(prefix, "libamd",                 :libamd),
    LibraryProduct(prefix, "libbtf",                 :libbtf),
    LibraryProduct(prefix, "libcamd",                :libcamd),
    LibraryProduct(prefix, "libccolamd",             :libccolamd),
    LibraryProduct(prefix, "libcolamd",              :libcolamd),
    LibraryProduct(prefix, "libcholmod",             :libcholmod),
    LibraryProduct(prefix, "libldl",                 :libldl),
    LibraryProduct(prefix, "libklu",                 :libklu),
    LibraryProduct(prefix, "libumfpack",             :libumfpack),
    LibraryProduct(prefix, "librbio",                :librbio),
    LibraryProduct(prefix, "libspqr",                :libspqr),
    LibraryProduct(prefix, "libsuitesparse_wrapper", :libsuitesparse_wrapper),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/OpenBLAS-v0.3.5-0/build_OpenBLAS.v0.3.5.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
