# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "Elemental"
# This is not really version 0.87.9, but taken from the master branch
# after 0.87.7. This is necessary to prevent C++ template
# instantiation errors with newer GCC versions.
version = v"0.87.9"

# Collection of sources required to build Elemental
sources = [
    GitSource("https://github.com/elemental/Elemental.git",
              "6eb15a0da2a4998bf1cf971ae231b78e06d989d9"),
]

# Bash recipe for building across all platforms
script = raw"""
if [[ "$nbits" == "64" ]]; then
  INT64="ON"
else
  INT64="OFF"
fi

if [[ "$nbits" == "64" ]]; then
  BLAS_LAPACK_LIB="$libdir/libopenblas64_.$dlext"
  BLAS_LAPACK_SUFFIX="_64_"
  BLAS_INT64="ON"
else
  BLAS_LAPACK_LIB="$libdir/libopenblas.$dlext"
  BLAS_LAPACK_SUFFIX=""
  BLAS_INT64="OFF"
fi

mkdir "$WORKSPACE/srcdir/$SRC_NAME/build"
cd "$WORKSPACE/srcdir/$SRC_NAME/build"

cmake \
  -DCMAKE_INSTALL_PREFIX="$prefix" \
  -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TARGET_TOOLCHAIN" \
  -DCMAKE_BUILD_TYPE="Release" \
  -DEL_USE_64BIT_INTS="$INT64" \
  -DEL_USE_64BIT_BLAS_INTS="$BLAS_INT64" \
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

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# MPItrampoline is not supported on `libgfortran3`. We need to expand
# the gfortran versions here so that we can exclude it. Otherwise,
# BinaryBuilder might choose `libgfortran3`, and the build will fail
# since no MPI implementation is available.
platforms = expand_gfortran_versions(platforms)

filter!(!Sys.iswindows, platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms)
# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# With MPItrampoline, select only those platforms where MPItrampoline is actually built
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && (Sys.iswindows(p) || libc(p) == "musl")), platforms)

# We encounter ICE on these architectures:
# - aarch64-linux-gnu-libgfortran4-cxx11-mpi+mpitrampoline
# - aarch64-linux-musl-libgfortran3-cxx11-mpi+mpich
# - aarch64-linux-musl-libgfortran3-cxx11-mpi+mpich
# - aarch64-linux-musl-libgfortran4-cxx03-mpi+openmpi
platforms = filter(p -> !(arch(p) == "aarch64" && Sys.islinux(p) && libgfortran_version(p) ≤ v"4"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libEl", :libEl),
    LibraryProduct("libElSuiteSparse", :libElSuiteSparse),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("METIS_jll"),
    Dependency("OpenBLAS_jll"),
]

append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
# GCC 4 does not support -std=c++14
# GCC 5 does not support the OpenMP function `omp_get_num_places`
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"6")
