# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "STRUMPACK"
version = v"8.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/pghysels/STRUMPACK.git",
              "9a45f304f21e1d9c44c6fa50ac2f044ab15cf342")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/STRUMPACK

# Set LD_LIBRARY_PATH so CMake can find the libraries
export LD_LIBRARY_PATH="${libdir}:${LD_LIBRARY_PATH}"

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DSTRUMPACK_USE_MPI=OFF \
    -DSTRUMPACK_USE_OPENMP=ON \
    -DSTRUMPACK_USE_CUDA=OFF \
    -DSTRUMPACK_USE_HIP=OFF \
    -DSTRUMPACK_USE_SYCL=OFF \
    -DTPL_BLAS_LIBRARIES="-lblastrampoline" \
    -DTPL_LAPACK_LIBRARIES="-llapack -lblastrampoline -fopenmp -lgfortran" \
    -DTPL_ENABLE_SLATE=OFF \
    -DTPL_ENABLE_PARMETIS=OFF \
    -DTPL_ENABLE_SCOTCH=OFF \
    -DTPL_ENABLE_PTSCOTCH=OFF \
    -DTPL_ENABLE_BPACK=OFF \
    -DTPL_ENABLE_COMBBLAS=OFF \
    -DTPL_ENABLE_ZFP=OFF \
    -DTPL_ENABLE_SZ3=OFF \
    -DTPL_ENABLE_MAGMA=OFF \
    -DTPL_ENABLE_KBLAS=OFF \
    -DTPL_ENABLE_PAPI=OFF \
    -DTPL_ENABLE_MATLAB=OFF \
    -DSTRUMPACK_COUNT_FLOPS=OFF \
    -DSTRUMPACK_TASK_TIMERS=OFF \
    -DSTRUMPACK_MESSAGE_COUNTER=OFF \
    -DSTRUMPACK_BUILD_TESTS=OFF \
    ..

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libstrumpack", :libstrumpack)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93")),
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2")),
    Dependency(PackageSpec(name="LAPACK_jll", uuid="51474c39-65e3-53ba-86ba-03b1b862ec14")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
