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

# Switch `ar` usage on OSX
if [[ ${target} == "x86_64-apple-darwin14" ]]; then
    export AR=/opt/${target}/bin/${target}-ar
fi

if [[ ${nbits} == 64 ]]; then
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
${CC} -shared ${WHOLE_ARCHIVE} ${prefix}/lib/libsuitesparseconfig.a ${NO_WHOLE_ARCHIVE} -o ${prefix}/lib/libsuitesparseconfig.${dlext} ${LDFLAGS} -L${prefix}/lib
for name in libamd libcolamd libcamd libccolamd; do
    ${CC} -shared ${WHOLE_ARCHIVE} ${prefix}/lib/${name}.a ${NO_WHOLE_ARCHIVE} -o ${prefix}/lib/${name}.${dlext} ${LDFLAGS} -L${prefix}/lib -lsuitesparseconfig
done
${CXX} -shared ${WHOLE_ARCHIVE} ${prefix}/lib/libcholmod.a ${NO_WHOLE_ARCHIVE} -o ${prefix}/lib/libcholmod.${dlext} ${LDFLAGS} -L${prefix}/lib -lcolamd -lamd -lcamd -lccolamd -lsuitesparseconfig -l${BLASNAME}
${CXX} -shared ${WHOLE_ARCHIVE} ${prefix}/lib/libumfpack.a ${NO_WHOLE_ARCHIVE} -o ${prefix}/lib/libumfpack.${dlext} ${LDFLAGS} -L${prefix}/lib -lcholmod -lcolamd -lamd -lsuitesparseconfig -l${BLASNAME}
${CXX} -shared ${WHOLE_ARCHIVE} ${prefix}/lib/libspqr.a ${NO_WHOLE_ARCHIVE} -o ${prefix}/lib/libspqr.${dlext} ${LDFLAGS} -L${prefix}/lib -lcholmod -lcolamd -lamd -lsuitesparseconfig -l${BLASNAME}

# For now, we'll have to adjust the name of the OpenBLAS library on macOS.
# Eventually, this should be fixed upstream
if [[ ${target} == "x86_64-apple-darwin14" ]]; then
    echo "-- Modifying library name for OpenBLAS"

    for nm in libcholmod libspqr libumfpack; do
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
