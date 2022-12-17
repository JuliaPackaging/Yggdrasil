include("../common.jl")

name = "SuiteSparse"

# Bash recipe for building across all platforms
script = raw"""
apk add --upgrade cmake --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main

cd $WORKSPACE/srcdir/SuiteSparse

# Disable OpenMP as it will probably interfere with blas threads and Julia threads
FLAGS+=(INSTALL="${prefix}" INSTALL_LIB="${libdir}" INSTALL_INCLUDE="${prefix}/include" CFOPENMP=)

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

for proj in SuiteSparse_config AMD BTF CAMD CCOLAMD COLAMD CHOLMOD LDL KLU UMFPACK RBio SPQR; do
    cd ${proj}/build
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DNOPENMP=ON \
        -DNPARTITION=ON \
        -DBLAS_FOUND=1 \
        -DBLAS64_SUFFIX="_64" \
        -DBLAS_LIBRARIES="${libdir}/libblastrampoline.${dlext}" \
        -DBLAS_LINKER_FLAGS="blastrampoline" \
        -DBLA_VENDOR="${BLAS_NAME}" \
        -DALLOW_64BIT_BLAS=ON \
        -DLAPACK_FOUND=1 \
        -DLAPACK_LINKER_FLAGS="blastrampoline" \
        -DLAPACK_LIBRARIES="${libdir}/libblastrampoline.${dlext}"
    make -j${nproc}
    make install
    cd $WORKSPACE/srcdir/SuiteSparse
done

# For now, we'll have to adjust the name of the Lbt library on macOS and FreeBSD.
# Eventually, this should be fixed upstream
if [[ ${target} == *-apple-* ]] || [[ ${target} == *freebsd* ]]; then
    BLAS_NAME="blastrampoline"
    echo "-- Modifying library name for Lbt"
    if [[ ${target} == *-apple-* ]]; then
        LBT_LINK=$(otool -L ${libdir}/${nm}.dylib | grep lib${BLAS_NAME} | awk '{ print $1 }')
        install_name_tool -change ${LBT_LINK} @rpath/lib${BLAS_NAME}.dylib ${libdir}/libsuitesparseconfig.dylib
    elif [[ ${target} == *freebsd* ]]; then
        LBT_LINK=$(readelf -d ${libdir}/${nm}.so | grep lib${BLAS_NAME} | sed -e 's/.*\[\(.*\)\].*/\1/')
        patchelf --replace-needed ${LBT_LINK} lib${BLAS_NAME}.so ${libdir}/libsuitesparseconfig.so
    fi
fi

# Delete the extra soversion libraries built. https://github.com/JuliaPackaging/Yggdrasil/issues/7
if [[ "${target}" == *-mingw* ]]; then
    rm -f ${libdir}/lib*.*.${dlext}
    rm -f ${libdir}/lib*.*.*.${dlext}
fi

install_license LICENSE.txt
"""

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.7")
