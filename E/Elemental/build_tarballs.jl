# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Elemental"
version = v"0.87.7"

# Collection of sources required to build Elemental
sources = [
    GitSource("https://github.com/elemental/Elemental.git",
              "477e503a7a840cc1a75173552711b980505a0b06"),
]

# Bash recipe for building across all platforms
script = raw"""
if [[ $nbits == 64 ]] && [[ "$target" != aarch64-* ]]; then
  BLAS_LAPACK_LIB="$libdir/libopenblas64_.$dlext"
  BLAS_LAPACK_SUFFIX="_64_"
else
  BLAS_LAPACK_LIB="$libdir/libopenblas.$dlext"
  BLAS_LAPACK_SUFFIX=""
fi

mkdir "$WORKSPACE/srcdir/$SRC_NAME/build"
cd "$WORKSPACE/srcdir/$SRC_NAME/build"

cmake \
  -DCMAKE_INSTALL_PREFIX="$prefix" \
  -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TARGET_TOOLCHAIN" \
  -DCMAKE_BUILD_TYPE="Release" \
  -DEL_DISABLE_PARMETIS="ON" \
  -DMETIS_TEST_RUNS_EXITCODE="0" \
  -DMETIS_TEST_RUNS_EXITCODE__TRYRUN_OUTPUT="" \
  -DMATH_LIBS="$BLAS_LAPACK_LIB" \
  -DBLAS_LIBRARIES="$BLAS_LAPACK_LIB" \
  -DLAPACK_LIBRARIES="$BLAS_LAPACK_LIB" \
  -DEL_BLAS_SUFFIX="$BLAS_LAPACK_SUFFIX" \
  -DEL_LAPACK_SUFFIX="$BLAS_LAPACK_SUFFIX" \
  "$WORKSPACE/srcdir/$SRC_NAME"

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
    LibraryProduct("libEl", :libEl),
    LibraryProduct("libElSuiteSparse", :libElSuiteSparse),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("METIS_jll"),
    Dependency("MPICH_jll"),
    Dependency("OpenBLAS_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
