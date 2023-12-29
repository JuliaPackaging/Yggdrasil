include("../common.jl")

using Base.BinaryPlatforms: arch, os

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "SuiteSparse_GPU"
version = v"5.10.1"

sources = suitesparse_sources(version)
push!(sources, DirectorySource("./bundled"))

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SuiteSparse

# Apply Jameson's shlib patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/SuiteSparse-shlib.patch

# Disable OpenMP as it will probably interfere with blas threads and Julia threads
FLAGS+=(INSTALL="${prefix}" INSTALL_LIB="${libdir}" INSTALL_INCLUDE="${prefix}/include" CFOPENMP=)

FLAGS+=(UNAME="$(uname)")
FLAGS+=(LDFLAGS="${LDFLAGS} -L${libdir}")

BLAS_NAME=blastrampoline
if [[ ${nbits} == 64 ]]; then
    SUN="-DSUN64 -DLONGBLAS='long long'"
fi

FLAGS+=(BLAS="-l${BLAS_NAME}" LAPACK="-l${BLAS_NAME}")

# Enable CUDA
FLAGS+=(CUDA_PATH="$prefix/cuda")

# To disable METIS in CHOLMOD, pass -DNPARTITION and avoiding linking metis
FLAGS+=(MY_METIS_LIB="-lmetis" MY_METIS_INC="${prefix}/include")
FLAGS+=(UMFPACK_CONFIG="$SUN" CHOLMOD_CONFIG+="$SUN" SPQR_CONFIG="$SUN")

make -j${nproc} -C SuiteSparse_config "${FLAGS[@]}" library config

for proj in SuiteSparse_config SuiteSparse_GPURuntime GPUQREngine CHOLMOD SPQR; do
    make -j${nproc} -C $proj "${FLAGS[@]}" library CFOPENMP="$CFOPENMP"
    make -j${nproc} -C $proj "${FLAGS[@]}" install CFOPENMP="$CFOPENMP"
done

# For now, we'll have to adjust the name of the OpenBLAS library on macOS and FreeBSD.
# Eventually, this should be fixed upstream
if [[ ${target} == *-apple-* ]] || [[ ${target} == *freebsd* ]]; then
    echo "-- Modifying library name for BLAS"

    for nm in libcholmod libspqr libumfpack; do
        # Figure out what version it probably latched on to:
        if [[ ${target} == *-apple-* ]]; then
            BLAS_LINK=$(otool -L ${libdir}/${nm}.dylib | grep lib${BLAS_NAME} | awk '{ print $1 }')
            install_name_tool -change ${BLAS_LINK} @rpath/lib${BLAS_NAME}.dylib ${libdir}/${nm}.dylib
        elif [[ ${target} == *freebsd* ]]; then
            BLAS_LINK=$(readelf -d ${libdir}/${nm}.so | grep lib${BLAS_NAME} | sed -e 's/.*\[\(.*\)\].*/\1/')
            patchelf --replace-needed ${BLAS_LINK} lib${BLAS_NAME}.so ${libdir}/${nm}.so
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
platforms = CUDA.supported_platforms()
filter!(p -> arch(p) == "x86_64", platforms)

dependencies = [
    Dependency("libblastrampoline_jll"),
    Dependency("SuiteSparse_jll"),
    Dependency("METIS_jll"),
 ]

products = [
    LibraryProduct("libsuitesparseconfig",      :libsuitesparseconfig),
    LibraryProduct("libcholmod",                :libcholmod),
    LibraryProduct("libspqr",                   :libspqr),
    LibraryProduct("libGPUQREngine",            :libGPUQREngine),
    LibraryProduct("libSuiteSparse_GPURuntime", :libSuiteSparse_GPURuntime),
]

# build SuiteSparse for all supported CUDA toolkits
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform)

    build_tarballs(ARGS, name, version, sources, script, [platform],
                   products, [dependencies; cuda_deps]; lazy_artifacts=true,
                   julia_compat="1.7", augment_platform_block=CUDA.augment,
                   skip_audit=true, dont_dlopen=true)
end
