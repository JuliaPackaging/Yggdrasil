using BinaryBuilder

name = "Sundials"
version = v"3.1.1"

# Collection of sources required to build SundialsBuilder
sources = [
    "https://github.com/LLNL/sundials/archive/v$(version).tar.gz" =>
    "d03fca24d7adbfe52e05bd4e61340251e1cf56927540cc77a1ca817716091166",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sundials-*/
patch -p0 < $WORKSPACE/srcdir/patches/Sundials_windows.patch

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}")
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release -DEXAMPLES_ENABLE_C=OFF)
CMAKE_FLAGS+=(-DKLU_ENABLE=ON -DKLU_INCLUDE_DIR="$prefix/include" -DKLU_LIBRARY_DIR="$libdir")
CMAKE_FLAGS+=(-DBLAS_ENABLE=ON -DLAPACK_ENABLE=ON)

if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
    patch -p0 < $WORKSPACE/srcdir/patches/Sundials_ilp64.patch
    CMAKE_FLAGS+=(-DBLAS_LIBRARIES="-L${libdir} -lopenblas64_" -DLAPACK_LIBRARIES="-L${libdir} -lopenblas64_")
else
    CMAKE_FLAGS+=(-DBLAS_LIBRARIES="-L${libdir} -lopenblas" -DLAPACK_LIBRARIES="-L${libdir} -lopenblas")
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
    LibraryProduct("libsundials_sunlinsolspfgmr", :libsundials_sunlinsolspfgmr),
    LibraryProduct("libsundials_ida", :libsundials_ida),
    LibraryProduct("libsundials_cvode", :libsundials_cvode),
    LibraryProduct("libsundials_cvodes", :libsundials_cvodes),
    LibraryProduct("libsundials_sunmatrixdense", :libsundials_sunmatrixdense),
    LibraryProduct("libsundials_sunlinsolspbcgs", :libsundials_sunlinsolspbcgs),
    LibraryProduct("libsundials_idas", :libsundials_idas),
    LibraryProduct("libsundials_nvecserial", :libsundials_nvecserial),
    LibraryProduct("libsundials_sunlinsoldense", :libsundials_sunlinsoldense),
    LibraryProduct("libsundials_sunlinsolspgmr", :libsundials_sunlinsolspgmr),
    LibraryProduct("libsundials_sunlinsolpcg", :libsundials_sunlinsolpcg),
    LibraryProduct("libsundials_sunlinsolsptfqmr", :libsundials_sunlinsolsptfqmr),
    LibraryProduct("libsundials_sunlinsolklu", :libsundials_sunlinsolklu),
    LibraryProduct("libsundials_sunmatrixsparse", :libsundials_sunmatrixsparse),
    LibraryProduct("libsundials_sunlinsolband", :libsundials_sunlinsolband),
    LibraryProduct("libsundials_sunmatrixband", :libsundials_sunmatrixband),
    LibraryProduct("libsundials_kinsol", :libsundials_kinsol),
    LibraryProduct("libsundials_arkode", :libsundials_arkode),
]

dependencies = [
    "OpenBLAS_jll",
    "SuiteSparse_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
