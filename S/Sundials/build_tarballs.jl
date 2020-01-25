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
# patch -p0 < $WORKSPACE/srcdir/patches/Sundials_windows.patch

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
export CFLAGS="-lgfortran -lquadmath"

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

products = Vector{LibraryProduct}()

dependencies = [
    "OpenBLAS_jll",
    "SuiteSparse_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
