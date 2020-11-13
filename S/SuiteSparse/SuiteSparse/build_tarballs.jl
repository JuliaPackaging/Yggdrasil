using BinaryBuilder

name = "SuiteSparse"
version = v"5.4.0"

# Collection of sources required to build SuiteSparse
sources = [
    ArchiveSource("https://github.com/DrTimothyAldenDavis/SuiteSparse/archive/v$(version).tar.gz",
                  "d9d62d539410d66550d0b795503a556830831f50087723cb191a030525eda770"),
    DirectorySource("./bundled"),
]


# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SuiteSparse-*

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

if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
    SUN="-DSUN64 -DLONGBLAS='long long'"
    BLAS_NAME=openblas64_
else
    BLAS_NAME=openblas
fi

FLAGS+=(BLAS="-l${BLAS_NAME}" LAPACK="-l${BLAS_NAME}")

# Disable METIS in CHOLMOD by passing -DNPARTITION and avoiding linking metis
#FLAGS+=(MY_METIS_LIB="-lmetis" MY_METIS_INC="${prefix}/include")
FLAGS+=(UMFPACK_CONFIG="$SUN" CHOLMOD_CONFIG+="$SUN -DNPARTITION" SPQR_CONFIG="$SUN")

make -j${nproc} -C SuiteSparse_config "${FLAGS[@]}" library config

for proj in SuiteSparse_config AMD BTF CAMD CCOLAMD COLAMD CHOLMOD LDL KLU UMFPACK RBio SPQR; do
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

# We enable experimental platforms as this is a core Julia dependency
platforms = supported_platforms(;experimental=true)

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
    Dependency("OpenBLAS_jll"),
#    Dependency("METIS_jll"),
]

# Note: we explicitly lie about this because we don't have the new
# versioning APIs worked out in BB yet.
version = v"5.4.1"
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
