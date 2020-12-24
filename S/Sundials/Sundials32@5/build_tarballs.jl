include("../common.jl")

name = "Sundials32"

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sundials*

# Set up LAPACK
LAPACK_LIBRARIES="-lgfortran ${libdir}/libopenblas.${dlext}"
if [[ "${target}" == i686-* ]] || [[ "${target}" == x86_64-* ]]; then
    LAPACK_LIBRARIES="${LAPACK_LIBRARIES} -lquadmath"
elif [[ "${target}" == powerpc64le-* ]]; then
    LAPACK_LIBRARIES="${LAPACK_LIBRARIES} -lgomp -ldl -lm -lpthread"
fi

# Set up CFLAGS
cd cmake/tpl
if [[ "${target}" == *-mingw* ]]; then
    atomic_patch $WORKSPACE/srcdir/patches/Sundials_windows.patch
    # Work around https://github.com/LLNL/sundials/issues/29
    export CFLAGS="${CFLAGS} -DBUILD_SUNDIALS_LIBRARY"
elif [[ "${target}" == powerpc64le-* ]]; then
    export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib64"
fi

# Fix the SuperLU_MT library name
atomic_patch $WORKSPACE/srcdir/patches/Sundials_SuperLU_MT.patch

# Use GCC on Apple/FreeBSD
toolchain="$CMAKE_TARGET_TOOLCHAIN"
if [[ "${target}" == *-apple-* ]] || [[ "${target}" == *-freebsd* ]]; then
    toolchain="${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake"
fi
# Set the mangling scheme manually on Apple
if [[ "${target}" == *-apple-* ]]; then
    mangling="-DSUNDIALS_F77_FUNC_CASE=lower -DSUNDIALS_F77_FUNC_UNDERSCORES=one"
fi

# Build
cd $WORKSPACE/srcdir/sundials*
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE="$toolchain" \
    -DEXAMPLES_ENABLE_C=OFF \
    -DENABLE_KLU=ON \
    -DKLU_INCLUDE_DIR="${includedir}" \
    -DKLU_LIBRARY_DIR="${libdir}" \
    -DENABLE_LAPACK=ON \
    -DLAPACK_LIBRARIES:STRING="${LAPACK_LIBRARIES}" \
    -DENABLE_SUPERLUMT=ON \
    -DSUPERLUMT_INCLUDE_DIR="${includedir}" \
    -DSUPERLUMT_LIBRARY_DIR="${libdir}" \
    -DSUPERLUMT_LIBRARIES="${libdir}/libopenblas.${dlext}" \
    -DSUPERLUMT_THREAD_TYPE="OpenMP" \
    -DSUNDIALS_INDEX_SIZE=32 \
    -DBUILD_STATIC_LIBS=OFF \
    ${mangling} \
    ..
make -j${nproc}
make install
# Move libraries to ${libdir} on Windows
if [[ "${target}" == *-mingw* ]]; then
    mv ${prefix}/lib/libsundials_*.${dlext} "${libdir}"
fi
"""

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS32_jll"),
    BuildDependency("SuiteSparse32_jll"),
    Dependency("SuperLU_MT_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"6")
