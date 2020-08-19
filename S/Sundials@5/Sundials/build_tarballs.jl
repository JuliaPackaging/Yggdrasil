include("../common.jl")

name = "Sundials"

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sundials*

# Set up CFLAGS
if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 $WORKSPACE/srcdir/patches/Sundials_windows.patch
    # Work around https://github.com/LLNL/sundials/issues/29
    export CFLAGS="${CFLAGS} -DBUILD_SUNDIALS_LIBRARY"
elif [[ "${target}" == powerpc64le-* ]]; then
    export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib64"
fi

# Set up LAPACK
LAPACK_LIBRARIES="-lgfortran"
if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
    atomic_patch -p1 $WORKSPACE/srcdir/patches/Sundials_Fortran.patch
    LAPACK_LIBRARIES="${LAPACK_LIBRARIES} ${libdir}/libopenblas64_.${dlext}"
else
    LAPACK_LIBRARIES="${LAPACK_LIBRARIES} ${libdir}/libopenblas.${dlext}"
fi
if [[ "${target}" == i686-* ]] || [[ "${target}" == x86_64-* ]]; then
    LAPACK_LIBRARIES="${LAPACK_LIBRARIES} -lquadmath"
elif [[ "${target}" == powerpc64le-* ]]; then
    LAPACK_LIBRARIES="${LAPACK_LIBRARIES} -lgomp -ldl -lm -lpthread"
fi

# Build
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DEXAMPLES_ENABLE_C=OFF \
    -DKLU_ENABLE=ON -DKLU_INCLUDE_DIR="$prefix/include" -DKLU_LIBRARY_DIR="$libdir" \
    -DLAPACK_ENABLE=ON -DLAPACK_LIBRARIES:STRING="${LAPACK_LIBRARIES}" \
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
    Dependency("OpenBLAS_jll"),
    Dependency("SuiteSparse_jll"),
]

build()
