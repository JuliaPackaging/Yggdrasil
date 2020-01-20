using BinaryBuilder

name = "SuiteSparse"
version = v"4.4.5"

# Collection of sources required to build SuiteSparse
sources = [
    "http://faculty.cse.tamu.edu/davis/SuiteSparse/SuiteSparse-$(version).tar.gz" =>
    "83f4b88657c7dc57681633e8ca6835ddb12c146bc51af77b6494972ed1ea8bc9",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SuiteSparse/

FLAGS=(INSTALL="${prefix}" INSTALL_LIB="${prefix}/lib" INSTALL_INCLUDE="${prefix}/include")

if [[ ${target} == *mingw32* ]]; then
    FLAGS+=(UNAME=Windows)
    FLAGS+=(LDFLAGS="${LDFLAGS} -L${prefix}/lib -shared")
    FLAGS+=(CFOPENMP=)
else
    FLAGS+=(UNAME="$(uname)")
    FLAGS+=(LDFLAGS="${LDFLAGS} -L${prefix}/lib")
fi

if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
    SUN="-DSUN64 -DLONGBLAS='long long'"

    BLASNAME=openblas64_
    FLAGS+=(BLAS="-lopenblas64_" LAPACK="-lopenblas64_")
    FLAGS+=(UMFPACK_CONFIG="$SUN" CHOLMOD_CONFIG="$SUN -DNPARTITION" SPQR_CONFIG="$SUN")
else
    BLASNAME=openblas
    FLAGS+=(BLAS="-lopenblas" LAPACK="-lopenblas")
    FLAGS+=(CHOLMOD_CONFIG="-DNPARTITION")
fi

if [[ ${target} == *apple* ]]; then
    WHOLE_ARCHIVE="-Xlinker -all_load"
elif [[ ${target} == *mingw* ]]; then
    WHOLE_ARCHIVE="-Wl,--whole-archive"
    NO_WHOLE_ARCHIVE="-Wl,--no-whole-archive"
fi

make -j -C SuiteSparse_config "${FLAGS[@]}" library
make -j -C SuiteSparse_config "${FLAGS[@]}" install

for proj in AMD BTF CAMD CCOLAMD COLAMD CHOLMOD LDL KLU UMFPACK RBio SPQR; do
    make -j -C $proj "${FLAGS[@]}" library CFOPENMP="$CFOPENMP"
    make -j -C $proj "${FLAGS[@]}" install CFOPENMP="$CFOPENMP"
done

# Manually build shared libraries
${CC} -shared ${WHOLE_ARCHIVE} ${prefix}/lib/libsuitesparseconfig.a ${NO_WHOLE_ARCHIVE} -o ${libdir}/libsuitesparseconfig.${dlext} ${LDFLAGS} -L${prefix}/lib
for name in libamd libcolamd libcamd libccolamd; do
        ${CC} -shared ${WHOLE_ARCHIVE} ${prefix}/lib/${name}.a ${NO_WHOLE_ARCHIVE} -o ${libdir}/${name}.${dlext} ${LDFLAGS} -L${prefix}/lib -lsuitesparseconfig
done
${CXX} -shared ${WHOLE_ARCHIVE} ${prefix}/lib/libcholmod.a ${NO_WHOLE_ARCHIVE} -o ${libdir}/libcholmod.${dlext} ${LDFLAGS} -L${prefix}/lib -lcolamd -lamd -lcamd -lccolamd -lsuitesparseconfig -l${BLASNAME}
${CXX} -shared ${WHOLE_ARCHIVE} ${prefix}/lib/libumfpack.a ${NO_WHOLE_ARCHIVE} -o ${libdir}/libumfpack.${dlext} ${LDFLAGS} -L${prefix}/lib -lcholmod -lcolamd -lamd -lsuitesparseconfig -l${BLASNAME}
${CXX} -shared ${WHOLE_ARCHIVE} ${prefix}/lib/libspqr.a ${NO_WHOLE_ARCHIVE} -o ${libdir}/libspqr.${dlext} ${LDFLAGS} -L${prefix}/lib -lcholmod -lcolamd -lamd -lsuitesparseconfig -l${BLASNAME}

# For now, we'll have to adjust the name of the OpenBLAS library on macOS.
# Eventually, this should be fixed upstream
if [[ ${target} == *-apple-* ]]; then
    echo "-- Modifying library name for OpenBLAS"

    for nm in libcholmod libspqr libumfpack; do
        # Figure out what version it probably latched on to:
        OPENBLAS_LINK=$(otool -L ${libdir}/${nm}.dylib | grep libopenblas64_ | awk '{ print $1 }')
        install_name_tool -change ${OPENBLAS_LINK} @rpath/libopenblas64_.dylib ${prefix}/lib/${nm}.dylib
    done
fi

# Compile suitesparse_wrapper shim
cd $WORKSPACE/srcdir/SuiteSparse_wrapper
make "${FLAGS[@]}" install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
# Temporarily commenting out static-only libraries
products = [
    LibraryProduct("libsuitesparseconfig",   :libsuitesparseconfig),
    LibraryProduct("libamd",                 :libamd),
    #LibraryProduct("libbtf",                 :libbtf),
    LibraryProduct("libcamd",                :libcamd),
    LibraryProduct("libccolamd",             :libccolamd),
    LibraryProduct("libcolamd",              :libcolamd),
    LibraryProduct("libcholmod",             :libcholmod),
    #LibraryProduct("libldl",                 :libldl),
    #LibraryProduct("libklu",                 :libklu),
    LibraryProduct("libumfpack",             :libumfpack),
    #LibraryProduct("librbio",                :librbio),
    LibraryProduct("libspqr",                :libspqr),
    LibraryProduct("libsuitesparse_wrapper", :libsuitesparse_wrapper),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "OpenBLAS_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
