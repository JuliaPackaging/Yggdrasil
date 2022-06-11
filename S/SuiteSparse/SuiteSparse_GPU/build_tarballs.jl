include("../common.jl")

name = "SuiteSparse_GPU"

sources = [
    sources;
    DirectorySource("./bundled")
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

BLAS_NAME=blastrampoline
if [[ ${nbits} == 64 ]]; then
    SUN="-DSUN64 -DLONGBLAS='long long'"
fi

FLAGS+=(BLAS="-l${BLAS_NAME}" LAPACK="-l${BLAS_NAME}")

# CUDA
FLAGS+=(CUDA_PATH="$prefix/cuda")

# METIS
FLAGS+=(MY_METIS_LIB="-lmetis" MY_METIS_INC="${prefix}/include")

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
"""

# Override the default platforms
platforms = [
    Platform("x86_64", "linux"),
]

append!(products, [
    LibraryProduct("libsliplu",                 :libsliplu),
#    LibraryProduct("libmongoose",               :libmongoose),
    LibraryProduct("libGPUQREngine",            :libGPUQREngine),
    LibraryProduct("libSuiteSparse_GPURuntime", :libSuiteSparse_GPURuntime),
])

dependencies = [
    dependencies;
    Dependency("METIS_jll")
    Dependency("MPFR_jll")
    Dependency("GMP_jll")
    BuildDependency(PackageSpec(name="CUDA_full_jll", version=v"10.0.130"))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"6")
