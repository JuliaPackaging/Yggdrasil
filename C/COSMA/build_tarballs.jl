# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "COSMA"
version = v"2.5.2"
cosma_version = v"2.5.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/eth-cscs/COSMA/releases/download/v$(cosma_version)/COSMA-v$(cosma_version).tar.gz",
                  "085b7787597374244bbb1eb89bc69bf58c35f6c85be805e881e1c0b25166c3ce")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

if [[ "$nbits" == "64" ]]; then
    BLAS_LAPACK_LIB="$libdir/libopenblas64_.$dlext"

    # Fix suffixes for 64-bit OpenBLAS
    SYMB_DEFS=()
    for sym in cblas_sgemm cblas_dgemm cblas_cgemm cblas_zgemm; do
        SYMB_DEFS+=("-D${sym}=${sym}64_")
    done
    export CXXFLAGS="${SYMB_DEFS[@]}"
else
    BLAS_LAPACK_LIB="$libdir/libopenblas.$dlext"
fi

# We should probably check the compiler instead
if [[ "$target" == x86_64-apple-darwin14 ]] || [[ "$target" == x86_64-unknown-freebsd11.1 ]]; then
    OMP_LIB=`find $libdir -iname 'libgomp.[^0-9]*'`
    OPENMP_CMAKE_FLAGS="-DOpenMP_CXX_FLAGS=-fopenmp=libgomp -DOpenMP_CXX_LIB_NAMES=gomp -DOpenMP_gomp_LIBRARY=$OMP_LIB"
    OMP_HEADER=`find / -name omp.h 2>/dev/null | head -n1`
    mkdir include
    cp $OMP_HEADER include
    export CPATH="$CPATH:$PWD/include"
else
    OPENMP_CMAKE_FLAGS=
fi

mkdir build
cd build

cmake ../COSMA-* \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCOSMA_WITH_TESTS=OFF \
    -DCOSMA_WITH_APPS=OFF \
    -DCOSMA_WITH_BENCHMARKS=OFF \
    -DCOSMA_WITH_INSTALL=ON \
    -DCOSMA_WITH_PROFILING=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DCOSMA_BLAS=OPENBLAS \
    -DCOSMA_SCALAPACK=OFF \
    -DMPI_C_COMPILER=$bindir/mpicc \
    -DMPI_CXX_COMPILER=$bindir/mpicxx \
    -DOPENBLAS_LIBRARIES=$BLAS_LAPACK_LIB \
    -DOPENBLAS_INCLUDE_DIR=$includedir \
    $OPENMP_CMAKE_FLAGS

make -j${nproc}
make install

install_license ../COSMA-*/LICENCE
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

filter!(!Sys.iswindows, platforms)

# OpenMP is not supported. The work-around for `apple` above does not work for `aarch64`.
filter!(p -> !(arch(p) == "aarch64" && Sys.isapple(p)), platforms)

# The products that we will ensure are always built
products = [
    # `libgrid2grid` existed in v2.2.0, but not any more in v2.5.1
    # LibraryProduct("libgrid2grid", :grid2grid),
    LibraryProduct("libcosma", :cosma),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS_jll", uuid="4536629a-c528-5b80-bd46-f80d51c5b363")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

platforms, platform_dependencies = MPI.augment_platforms(platforms)
# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && (Sys.iswindows(p) || libc(p) == "musl")), platforms)
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.7", preferred_gcc_version = v"8")
