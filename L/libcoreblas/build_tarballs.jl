# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libcoreblas"
version = v"23.8.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Rabab53/CoreBlas.git", "a0550b87d7b94aff49e65e8a79c5d884f5a08680")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
BLAS_NAME=blastrampoline
if [[ "${target}" == *-mingw* ]]; then
    BLAS_LIB=${BLAS_NAME}-5;
else
    BLAS_LIB=${BLAS_NAME};
fi

if [[ ${nbits} == 64 ]]; then
    CMAKE_OPTIONS=(-DCOREBLAS_USE_64BIT_BLAS=ON);
else
CMAKE_OPTIONS=(-DCOREBLAS_USE_64BIT_BLAS=OFF);
fi

cd CoreBlas/

 cmake -B build -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release \
        -DBLAS_FOUND=1 \
        -DBLAS_LIBRARIES="${libdir}/lib${BLAS_LIB}.${dlext}" \
        -DBLAS_LINKER_FLAGS="${BLAS_LIB}" \
        -DBLA_VENDOR="${BLAS_NAME}" \
        -DLAPACK_LIBRARIES="${libdir}/lib${BLAS_LIB}.${dlext}" \
        -DLAPACK_LINKER_FLAGS="${BLAS_LIB}" \
        "${CMAKE_OPTIONS[@]}"  \
        -DCMAKE_C_FLAGS="-I/workspace/destdir/include/libblastrampoline/ILP64/${target}"


cmake --build build --parallel ${nproc}
cmake --install build
logout
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libcoreblas", :libcoreblas)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
