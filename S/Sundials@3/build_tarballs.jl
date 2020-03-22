using BinaryBuilder

name = "Sundials"
version = v"3.1.2"

# Collection of sources required to build SundialsBuilder
sources = [
    "https://github.com/LLNL/sundials/archive/v$(version).tar.gz" =>
    "a8985bb1e851d90e24260450667b134bc13d71f5c6effc9e1d7183bd874fe116",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sundials-*/
patch -p0 < $WORKSPACE/srcdir/patches/Sundials_windows.patch

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}")
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release -DEXAMPLES_ENABLE_C=OFF)
CMAKE_FLAGS+=(-DKLU_ENABLE=ON -DKLU_INCLUDE_DIR="$prefix/include" -DKLU_LIBRARY_DIR="$libdir")

### Disable BLAS and LAPACK because sundials 3.1 cannot use 64-bit ints with these libraries
#CMAKE_FLAGS+=(-DBLAS_ENABLE=ON -DLAPACK_ENABLE=ON)
#if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
#    patch -p0 < $WORKSPACE/srcdir/patches/Sundials_ilp64.patch
#    CMAKE_FLAGS+=(-DBLAS_LIBRARIES="-L${libdir} -lopenblas64_" -DLAPACK_LIBRARIES="-L${libdir} -lopenblas64_")
#else
#    CMAKE_FLAGS+=(-DBLAS_LIBRARIES="-L${libdir} -lopenblas" -DLAPACK_LIBRARIES="-L${libdir} -lopenblas")
#fi

if [[ ${target} != *darwin* ]]; then
    # Needed to find libgfortran for OpenBLAS.
    export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib -Wl,-rpath-link,/opt/${target}/${target}/lib64"
fi

mkdir build
cd build
cmake "${CMAKE_FLAGS[@]}" ..
make -j${nproc}
make install

# Move libraries to ${libdir} on Windows
if [[ "${target}" == *-mingw* ]]; then
    mv ${prefix}/lib/libsundials_*.${dlext} "${libdir}"
fi
"""

# We attempt to build for all defined platforms
platforms = supported_platforms()

products = [
    LibraryProduct("libsundials_arkode", :libsundials_arkode),
    LibraryProduct("libsundials_cvode", :libsundials_cvode),
    LibraryProduct("libsundials_cvodes", :libsundials_cvodes),
    LibraryProduct("libsundials_ida", :libsundials_ida),
    LibraryProduct("libsundials_idas", :libsundials_idas),
    LibraryProduct("libsundials_kinsol", :libsundials_kinsol),
    LibraryProduct("libsundials_nvecserial", :libsundials_nvecserial),
    LibraryProduct("libsundials_sunlinsolband", :libsundials_sunlinsolband),
    LibraryProduct("libsundials_sunlinsoldense", :libsundials_sunlinsoldense),
    LibraryProduct("libsundials_sunlinsolklu", :libsundials_sunlinsolklu),
    LibraryProduct("libsundials_sunlinsolpcg", :libsundials_sunlinsolpcg),
    LibraryProduct("libsundials_sunlinsolspbcgs", :libsundials_sunlinsolspbcgs),
    LibraryProduct("libsundials_sunlinsolspfgmr", :libsundials_sunlinsolspfgmr),
    LibraryProduct("libsundials_sunlinsolspgmr", :libsundials_sunlinsolspgmr),
    LibraryProduct("libsundials_sunlinsolsptfqmr", :libsundials_sunlinsolsptfqmr),
    LibraryProduct("libsundials_sunmatrixband", :libsundials_sunmatrixband),
    LibraryProduct("libsundials_sunmatrixdense", :libsundials_sunmatrixdense),
    LibraryProduct("libsundials_sunmatrixsparse", :libsundials_sunmatrixsparse),
]

dependencies = [
    "OpenBLAS_jll",
    "SuiteSparse_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
