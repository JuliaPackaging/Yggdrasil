# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Elemental"
version = v"1.3.3"

# Collection of sources required to build Elemental
sources = [
    GitSource("https://github.com/LLNL/Elemental.git",
              "38505fbf3b9f4a511fb35b0776144f336616fe38"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd Elemental

atomic_patch -p1 ../patches/01-fix-suffix.patch
if [[ "$target" == *86*-linux-musl* ]]; then
    pushd /opt/$target/lib/gcc/$target/*/include
    atomic_patch -p0 "$WORKSPACE/srcdir/patches/02-fix-musl.patch"
    popd
fi

mkdir build
cd build

if [[ "$nbits" == 64 ]]; then
  IS_64="ON"
else
  IS_64="OFF"
fi

if [[ "$nbits" == 64 ]] && [[ "$target" != aarch64-* ]]; then
  BLAS_LAPACK_LIB="$libdir/libopenblas64_.$dlext"
  IS_BLAS_64="ON"
else
  BLAS_LAPACK_LIB="$libdir/libopenblas.$dlext"
  IS_BLAS_64="OFF"
fi

cmake \
  -DCMAKE_INSTALL_PREFIX="$prefix" \
  -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TARGET_TOOLCHAIN" \
  -DCMAKE_BUILD_TYPE="Release" \
  -DBUILD_SHARED_LIBS="ON" \
  -DBLAS_LIBRARIES="$BLAS_LAPACK_LIB" \
  -DLAPACK_LIBRARIES="$BLAS_LAPACK_LIB" \
  -DHydrogen_ENABLE_TESTING="OFF" \
  -DHydrogen_USE_OpenBLAS="ON" \
  -DHydrogen_USE_64BIT_INTS="$IS_64" \
  -DHydrogen_USE_64BIT_BLAS_INTS="$IS_BLAS_64" \
  ..

make "-j$nproc"
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
filter!(p -> !(p isa Windows), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libHydrogen_CXX", :libHydrogen),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("MPICH_jll"),
    Dependency("OpenBLAS_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
