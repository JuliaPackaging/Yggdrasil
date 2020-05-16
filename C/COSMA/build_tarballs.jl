# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "COSMA"
version = v"2.2.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/eth-cscs/COSMA/releases/download/v2.2.0/cosma.tar.gz", "1eb92a98110df595070a12193b9221eecf9d103ced8836c960f6c79a2bd553ca"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

if [[ "$nbits" == "64" ]] && [[ "$target" != aarch64-* ]]; then
    BLAS_LAPACK_LIB="$libdir/libopenblas64_.$dlext"
else
    BLAS_LAPACK_LIB="$libdir/libopenblas.$dlext"
fi

if [[ "$target" == x86_64-apple-darwin14 ]] || [[ "$target" == x86_64-unknown-freebsd11.1 ]]; then
    OMP_LIB=`find $libdir -iname 'libgomp*'`
    OPENMP_CMAKE_FLAGS="-DOpenMP_CXX_FLAGS=-fopenmp=libgomp -DOpenMP_CXX_LIB_NAMES=gomp -DOpenMP_gomp_LIBRARY=$OMP_LIB"
    OMP_HEADER=`find / -name omp.h 2>/dev/null  | head -n1`
    mkdir include
    cp $OMP_HEADER include/
    export CPATH=$PWD/include
else
    OPENMP_CMAKE_FLAGS=
fi

mkdir build
cd build

cmake ../cosma \
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
    -DMPI_CXX_COMPILER=$bindir/mpicxx \
    -DMPI_C_COMPILER=$bindir/mpicc \
    -DOPENBLAS_LIBRARIES=$BLAS_LAPACK_LIB \
    -DOPENBLAS_INCLUDE_DIR=$includedir \
    $OPENMP_CMAKE_FLAGS

make -j$(nproc)
make install

# Manually copy license
install_license ../cosma/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
filter!(p -> !(p isa Windows), platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libgrid2grid", :grid2grid),
    LibraryProduct("libcosma", :cosma)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS_jll", uuid="4536629a-c528-5b80-bd46-f80d51c5b363")),
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0")
