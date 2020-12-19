using BinaryBuilder

name = "Sundials32"
version = v"5.6.1"

# Collection of sources required to build Sundials
sources = [
    GitSource("https://github.com/LLNL/sundials.git",
              "6ddce5d90084d8d1cbb8e12bb5a4402168325efe"),
    DirectorySource("../bundled@5"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sundials*

cd cmake/tpl

# Set up CFLAGS
if [[ "${target}" == *-mingw* ]]; then
    atomic_patch $WORKSPACE/srcdir/patches/Sundials_windows.patch
    # Work around https://github.com/LLNL/sundials/issues/29
    export CFLAGS="${CFLAGS} -DBUILD_SUNDIALS_LIBRARY"
elif [[ "${target}" == powerpc64le-* ]]; then
    export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib64"
fi

# Set up LAPACK
LAPACK_LIBRARIES="-lgfortran ${libdir}/libopenblas.${dlext}"
if [[ "${target}" == i686-* ]] || [[ "${target}" == x86_64-* ]]; then
    LAPACK_LIBRARIES="${LAPACK_LIBRARIES} -lquadmath"
elif [[ "${target}" == powerpc64le-* ]]; then
    LAPACK_LIBRARIES="${LAPACK_LIBRARIES} -lgomp -ldl -lm -lpthread"
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

# We attempt to build for all defined platforms
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
platforms = [p for p in platforms if !(arch(p) == :powerpc64le)]

products = [
    LibraryProduct("libsundials_arkode", :libsundials_arkode),
    LibraryProduct("libsundials_cvode", :libsundials_cvode),
    LibraryProduct("libsundials_cvodes", :libsundials_cvodes),
    LibraryProduct("libsundials_ida", :libsundials_ida),
    LibraryProduct("libsundials_idas", :libsundials_idas),
    LibraryProduct("libsundials_kinsol", :libsundials_kinsol),
    LibraryProduct("libsundials_nvecmanyvector", :libsundials_nvecmanyvector),
    LibraryProduct("libsundials_nvecserial", :libsundials_nvecserial),
    LibraryProduct("libsundials_sunlinsolband", :libsundials_sunlinsolband),
    LibraryProduct("libsundials_sunlinsoldense", :libsundials_sunlinsoldense),
    LibraryProduct("libsundials_sunlinsolklu", :libsundials_sunlinsolklu),
    LibraryProduct("libsundials_sunlinsollapackband", :libsundials_sunlinsollapackband),
    LibraryProduct("libsundials_sunlinsollapackdense", :libsundials_sunlinsollapackdense),
    LibraryProduct("libsundials_sunlinsolpcg", :libsundials_sunlinsolpcg),
    LibraryProduct("libsundials_sunlinsolspbcgs", :libsundials_sunlinsolspbcgs),
    LibraryProduct("libsundials_sunlinsolspfgmr", :libsundials_sunlinsolspfgmr),
    LibraryProduct("libsundials_sunlinsolspgmr", :libsundials_sunlinsolspgmr),
    LibraryProduct("libsundials_sunlinsolsptfqmr", :libsundials_sunlinsolsptfqmr),
    LibraryProduct("libsundials_sunmatrixband", :libsundials_sunmatrixband),
    LibraryProduct("libsundials_sunmatrixdense", :libsundials_sunmatrixdense),
    LibraryProduct("libsundials_sunmatrixsparse", :libsundials_sunmatrixsparse),
    LibraryProduct("libsundials_sunnonlinsolfixedpoint", :libsundials_sunnonlinsolfixedpoint),
    LibraryProduct("libsundials_sunnonlinsolnewton", :libsundials_sunnonlinsolnewton),
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS32_jll"),
    BuildDependency("SuiteSparse32_jll"),
    Dependency("SuperLU_MT_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"6")
