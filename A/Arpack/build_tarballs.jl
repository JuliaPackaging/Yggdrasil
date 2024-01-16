using BinaryBuilder

# Collection of sources required to build Arpack
name = "Arpack"
version = v"3.9.1"

sources = [
    GitSource("https://github.com/opencollab/arpack-ng.git",
              "40329031ae8deb7c1e26baf8353fa384fc37c251"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/arpack-ng*

if [[ "${target}" == *-mingw* ]]; then
    LBT=blastrampoline-5
else
    LBT=blastrampoline
fi

mkdir build
cd build

if [[ ${nbits} == 64 ]]; then
    cmake .. -DCMAKE_INSTALL_PREFIX="$prefix" \
        -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" -DCMAKE_BUILD_TYPE=Release \
        -DBLAS_LIBRARIES=${LBT} -DBLAS_LINKER_FLAGS="-L${libdir}" \
        -DLAPACK_LIBRARIES=${LBT} -DLAPACK_LINKER_FLAGS="-L${libdir}" \
        -DEXAMPLES=OFF \
        -DBUILD_SHARED_LIBS=ON \
        -DINTERFACE64=1 -DSYMBOLSUFFIX=_64
else
    cmake .. -DCMAKE_INSTALL_PREFIX="$prefix" \
        -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" -DCMAKE_BUILD_TYPE=Release \
        -DBLAS_LIBRARIES=${LBT} -DBLAS_LINKER_FLAGS="-L${libdir}" \
        -DLAPACK_LIBRARIES=${LBT} -DLAPACK_LINKER_FLAGS="-L${libdir}" \
        -DEXAMPLES=OFF \
        -DBUILD_SHARED_LIBS=ON
fi

make -j${nproc}
make install

# Delete the extra soversion libraries built. https://github.com/JuliaPackaging/Yggdrasil/issues/7
if [[ "${target}" == *-mingw* ]]; then
    rm -f ${libdir}/lib*.*.${dlext}
    rm -f ${libdir}/lib*.*.*.${dlext}
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We enable the full
# combinatorial explosion of GCC versions because this package most
# definitely links against libgfortran.
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libarpack", :libarpack),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libblastrampoline_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.8")
