using BinaryBuilder

name = "Sundials"
version = v"5.1.0"

# Collection of sources required to build SundialsBuilder
sources = [
    "https://github.com/LLNL/sundials/archive/v$(version).tar.gz" =>
    "101be83221f9a0ab185ecce04d003ba38660cc71eb81b8a7cf96d1cc08b3d7f9",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sundials-*/
if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 $WORKSPACE/srcdir/patches/Sundials_windows.patch
fi

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}")
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release -DEXAMPLES_ENABLE_C=OFF)
CMAKE_FLAGS+=(-DKLU_ENABLE=ON -DKLU_INCLUDE_DIR="$prefix/include" -DKLU_LIBRARY_DIR="$libdir")
CMAKE_FLAGS+=(-DLAPACK_ENABLE=ON)

if [[ ${nbits} == 64 ]] && [[ ${target} != aarch64* ]]; then
    atomic_patch -p1 $WORKSPACE/srcdir/patches/Sundials_Fortran.patch
    CMAKE_FLAGS+=(-DLAPACK_LIBRARIES="${libdir}/libopenblas64_.${dlext}")
else
    CMAKE_FLAGS+=(-DLAPACK_LIBRARIES="${libdir}/libopenblas.${dlext}")
fi
export CFLAGS="-lgfortran"
if [[ "${target}" == i686-* ]] || [[ "${target}" == x86_64-* ]]; then
    export CFLAGS="${CFLAGS} -lquadmath"
elif [[ "${target}" == powerpc64le-* ]]; then
    export CFLAGS="${CFLAGS} -lgomp -ldl -lm -lpthread -Wl,-rpath-link,/opt/${target}/${target}/lib64"
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
platforms = expand_gfortran_versions(platforms)

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
    "OpenBLAS_jll",
    "SuiteSparse_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"6")
