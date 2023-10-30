include("../common.jl")

name = "SuiteSparse"
version = v"7.3.0"

sources = suitesparse_sources(version)

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SuiteSparse

# Needs cmake >= 3.22 provided by jll
apk del cmake

# Disable OpenMP as it will probably interfere with blas threads and Julia threads
FLAGS+=(INSTALL="${prefix}" INSTALL_LIB="${libdir}" INSTALL_INCLUDE="${prefix}/include" CFOPENMP=)

if [[ "${target}" == *-mingw* ]]; then
    BLAS_NAME=blastrampoline-5
else
    BLAS_NAME=blastrampoline
fi

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

if [[ ${nbits} == 64 ]]; then
    CMAKE_OPTIONS=(
        -DBLAS64_SUFFIX="_64"
        -DALLOW_64BIT_BLAS=YES
    )
else
    CMAKE_OPTIONS=(
        -DALLOW_64BIT_BLAS=NO
    )
fi

for proj in SuiteSparse_config AMD BTF CAMD CCOLAMD COLAMD CHOLMOD LDL KLU UMFPACK RBio SPQR; do
    cd ${proj}/build
    cmake .. -DCMAKE_BUILD_TYPE=Release \
             -DCMAKE_INSTALL_PREFIX=${prefix} \
             -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
             -DENABLE_CUDA=0 \
             -DNFORTRAN=1 \
             -DNOPENMP=1 \
             -DNPARTITION=0 \
             -DNSTATIC=1 \
             -DBLAS_FOUND=1 \
             -DBLAS_LIBRARIES="${libdir}/lib${BLAS_NAME}.${dlext}" \
             -DBLAS_LINKER_FLAGS="${BLAS_NAME}" \
             -DBLAS_UNDERSCORE=ON \
             -DBLA_VENDOR="${BLAS_NAME}" \
             -DLAPACK_FOUND=1 \
             -DLAPACK_LIBRARIES="${libdir}/lib${BLAS_NAME}.${dlext}" \
             -DLAPACK_LINKER_FLAGS="${BLAS_NAME}" \
             "${CMAKE_OPTIONS[@]}"
    make -j${nproc}
    make install
    cd ../..
done

# For now, we'll have to adjust the name of the Lbt library on macOS and FreeBSD.
# Eventually, this should be fixed upstream
if [[ ${target} == *-apple-* ]] || [[ ${target} == *freebsd* ]]; then
    echo "-- Modifying library name for libblastrampoline"

    for nm in libcholmod libspqr libumfpack; do
        # Figure out what version it probably latched on to:
        if [[ ${target} == *-apple-* ]]; then
            LBT_LINK=$(otool -L ${libdir}/${nm}.dylib | grep lib${BLAS_NAME} | awk '{ print $1 }')
            install_name_tool -change ${LBT_LINK} @rpath/lib${BLAS_NAME}.dylib ${libdir}/${nm}.dylib
        elif [[ ${target} == *freebsd* ]]; then
            LBT_LINK=$(readelf -d ${libdir}/${nm}.so | grep lib${BLAS_NAME} | sed -e 's/.*\[\(.*\)\].*/\1/')
            patchelf --replace-needed ${LBT_LINK} lib${BLAS_NAME}.so ${libdir}/${nm}.so
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

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10")
