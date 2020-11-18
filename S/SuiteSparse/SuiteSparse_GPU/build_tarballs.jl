# This is an experimental build of SuiteSparse.

using BinaryBuilder, Pkg

name = "SuiteSparse_GPU"
version = v"5.8.1"

# Collection of sources required to build SuiteSparse
sources = [
    GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
              "1869379f464f0f8dac471edb4e6d010b2b0e639d"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SuiteSparse

# Apply Jameson's shlib patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/SuiteSparse-shlib.patch

# Disable OpenMP as it will probably interfere with blas threads and Julia threads
FLAGS+=(INSTALL="${prefix}" INSTALL_LIB="${libdir}" INSTALL_INCLUDE="${prefix}/include" CFOPENMP=)

if [[ ${target} == *mingw32* ]]; then
    FLAGS+=(UNAME=Windows)
    FLAGS+=(LDFLAGS="${LDFLAGS} -L${libdir} -shared")
else
    FLAGS+=(UNAME="$(uname)")
    FLAGS+=(LDFLAGS="${LDFLAGS} -L${libdir}")
fi

# OpenBLAS 
#if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
#    BLAS_64="-DSUN64 -DBLAS64 -DLONGBLAS='long long'"
#    BLAS_NAME=openblas64_
#else
#    BLAS_NAME=openblas
#fi
#FLAGS+=(BLAS="-l${BLAS_NAME}" LAPACK="-l${BLAS_NAME}")
#FLAGS+=(UMFPACK_CONFIG="$BLAS_64" CHOLMOD_CONFIG+="$BLAS_64" SPQR_CONFIG="$BLAS_64")

# MKL
FLAGS+=(MKLROOT="${prefix}")

# CUDA
FLAGS+=(CUDA_PATH="$prefix/cuda")

# METIS
FLAGS+=(MY_METIS_LIB="-lmetis" MY_METIS_INC="${prefix}/include")
# Disable METIS in CHOLMOD by passing -DNPARTITION and avoiding linking metis
#FLAGS+=(CHOLMOD_CONFIG+="-DNPARTITION")

make -j${nproc} -C SuiteSparse_config "${FLAGS[@]}" library config

for proj in SuiteSparse_config SuiteSparse_GPURuntime GPUQREngine AMD BTF CAMD CCOLAMD COLAMD CHOLMOD LDL KLU UMFPACK RBio SPQR SLIP_LU Mongoose; do
    make -j${nproc} -C $proj "${FLAGS[@]}" library CFOPENMP="$CFOPENMP"
    make -j${nproc} -C $proj "${FLAGS[@]}" install CFOPENMP="$CFOPENMP"
done

# For now, we'll have to adjust the name of the OpenBLAS library on macOS and FreeBSD.
# Eventually, this should be fixed upstream
if [[ ${target} == *-apple-* ]] || [[ ${target} == *freebsd* ]]; then
    echo "-- Modifying library name for OpenBLAS"

    for nm in libcholmod libspqr libumfpack; do
        # Figure out what version it probably latched on to:
        if [[ ${target} == *-apple-* ]]; then
            OPENBLAS_LINK=$(otool -L ${libdir}/${nm}.dylib | grep lib${BLAS_NAME} | awk '{ print $1 }')
            install_name_tool -change ${OPENBLAS_LINK} @rpath/lib${BLAS_NAME}.dylib ${libdir}/${nm}.dylib
        elif [[ ${target} == *freebsd* ]]; then
            OPENBLAS_LINK=$(readelf -d ${libdir}/${nm}.so | grep lib${BLAS_NAME} | sed -e 's/.*\[\(.*\)\].*/\1/')
            patchelf --replace-needed ${OPENBLAS_LINK} lib${BLAS_NAME}.so ${libdir}/${nm}.so
        fi
    done
fi

# Delete the extra soversion libraries built. https://github.com/JuliaPackaging/Yggdrasil/issues/7
if [[ "${target}" == *-mingw* ]]; then
    rm -f ${libdir}/lib*.*.${dlext}
    rm -f ${libdir}/lib*.*.*.${dlext}
fi

install_license LICENSE.txt

# Compile SuiteSparse_wrapper shim
cd $WORKSPACE/srcdir/SuiteSparse_wrapper
"${CC}" -O2 -shared -fPIC -I${prefix}/include SuiteSparse_wrapper.c -o ${libdir}/libsuitesparse_wrapper.${dlext} -L${libdir} -lcholmod
"""

platforms = [
    Platform("x86_64", "linux"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libsuitesparseconfig",      :libsuitesparseconfig),
    LibraryProduct("libamd",                    :libamd),
    LibraryProduct("libbtf",                    :libbtf),
    LibraryProduct("libcamd",                   :libcamd),
    LibraryProduct("libccolamd",                :libccolamd),
    LibraryProduct("libcolamd",                 :libcolamd),
    LibraryProduct("libcholmod",                :libcholmod),
    LibraryProduct("libldl",                    :libldl),
    LibraryProduct("libklu",                    :libklu),
    LibraryProduct("libumfpack",                :libumfpack),
    LibraryProduct("librbio",                   :librbio),
    LibraryProduct("libspqr",                   :libspqr),
    LibraryProduct("libsliplu",                 :libsliplu),
    LibraryProduct("libmongoose",               :libmongoose),
    LibraryProduct("libGPUQRengine",            :libGPUQRengine),
    LibraryProduct("libSuiteSparse_GPURuntime", :libSuiteSparse_GPURuntime),    
    LibraryProduct("libsuitesparse_wrapper",    :libsuitesparse_wrapper),
]

# Dependencies that must be installed before this package can be built
cuda_version = v"9.0.176"
dependencies = [
    Dependency("MKL_jll"),
    Dependency("METIS_jll"),
    Dependency("MPFR_jll"),
    Dependency("GMP_jll"),
    BuildDependency(PackageSpec(name="CUDA_full_jll", version=cuda_version))
]

# Note: we explicitly lie about this because we don't have the new
# versioning APIs worked out in BB yet.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
