include("../common.jl")

name = "SuiteSparse"
version = v"7.6.0"

sources = suitesparse_sources(version)

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SuiteSparse

# Needs cmake >= 3.22 provided by jll
apk del cmake

# Disable OpenMP as it will probably interfere with blas threads and Julia threads
FLAGS+=(INSTALL="${prefix}" INSTALL_LIB="${libdir}" INSTALL_INCLUDE="${prefix}/include" CFOPENMP=)

BLAS_NAME=blastrampoline
if [[ "${target}" == *-mingw* ]]; then
    BLAS_LIB=${BLAS_NAME}-5
else
    BLAS_LIB=${BLAS_NAME}
fi

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${libdir}/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

if [[ ${nbits} == 64 ]]; then
    CMAKE_OPTIONS=(
        -DBLAS64_SUFFIX="_64"
        -DSUITESPARSE_USE_64BIT_BLAS=YES
    )
else
    CMAKE_OPTIONS=(
        -DSUITESPARSE_USE_64BIT_BLAS=NO
    )
fi

PROJECTS_TO_BUILD="suitesparse_config;amd;btf;camd;ccolamd;colamd;cholmod;klu;ldl;umfpack;rbio;spqr"

cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DBUILD_STATIC_LIBS=OFF \
      -DBUILD_TESTING=OFF \
      -DSUITESPARSE_ENABLE_PROJECTS=${PROJECTS_TO_BUILD} \
      -DSUITESPARSE_DEMOS=OFF \
      -DSUITESPARSE_USE_STRICT=ON \
      -DSUITESPARSE_USE_CUDA=OFF \
      -DSUITESPARSE_USE_FORTRAN=OFF \
      -DSUITESPARSE_USE_OPENMP=OFF \
      -DCHOLMOD_PARTITION=ON \
      -DBLAS_FOUND=1 \
      -DBLAS_LIBRARIES="${libdir}/lib${BLAS_LIB}.${dlext}" \
      -DBLAS_LINKER_FLAGS="${BLAS_LIB}" \
      -DBLA_VENDOR="${BLAS_NAME}" \
      -DLAPACK_LIBRARIES="${libdir}/lib${BLAS_LIB}.${dlext}" \
      -DLAPACK_LINKER_FLAGS="${BLAS_LIB}" \
      "${CMAKE_OPTIONS[@]}" \
      .
make -j${nproc}
make install

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
               julia_compat="1.11")
