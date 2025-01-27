# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PaStiX"
version = v"6.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.inria.fr/solverstack/pastix.git", "1151c30a25e2014ff4b39bf8c7ac4b381913f193"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd pastix
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/pastix.patch
git submodule update --init --recursive

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/message.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/split_python.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/disable_scotch_int_check.patch

# We can't run executables in the cross-compiler
sed s/'morse_check_static_or_dynamic(CBLAS CBLAS_LIBRARIES)'/'# morse_check_static_or_dynamic(CBLAS CBLAS_LIBRARIES)'/ -i cmake_modules/morse_cmake/modules/find/FindCBLAS.cmake
sed s/'morse_check_static_or_dynamic(LAPACKE LAPACKE_LIBRARIES)'/'# morse_check_static_or_dynamic(LAPACKE LAPACKE_LIBRARIES)'/ -i cmake_modules/morse_cmake/modules/find/FindLAPACKE.cmake
sed s/'check_c_source_runs("${METIS_C_TEST_METIS_Idx_4}" METIS_Idx_4)'/'set(METIS_Idx_4 1)'/ -i cmake_modules/morse_cmake/modules/find/FindMETIS.cmake
sed s/'check_c_source_runs("${METIS_C_TEST_METIS_Idx_8}" METIS_Idx_8)'/'set(METIS_Idx_8 0)'/ -i cmake_modules/morse_cmake/modules/find/FindMETIS.cmake
sed s/'check_c_source_runs("${SCOTCH_C_TEST_SCOTCH_Num_4}" SCOTCH_Num_4)'/'set(SCOTCH_Num_4 1)'/ -i cmake_modules/morse_cmake/modules/find/FindSCOTCH.cmake
sed s/'check_c_source_runs("${SCOTCH_C_TEST_SCOTCH_Num_8}" SCOTCH_Num_8)'/'set(SCOTCH_Num_8 0)'/ -i cmake_modules/morse_cmake/modules/find/FindSCOTCH.cmake

# We don't want to compute the tests and the examples
sed s/'enable_testing()'/'# enable_testing()'/ -i CMakeLists.txt
sed s/'include(CTest)'/'# include(CTest)'/ -i CMakeLists.txt
sed s/'add_subdirectory(example)'/'# add_subdirectory(example)'/ -i CMakeLists.txt
sed s/'add_subdirectory(test)'/'# add_subdirectory(test)'/ -i CMakeLists.txt

mkdir build
cd build

# BLAS and LAPACK
if [[ "${target}" == *mingw* ]]; then
  LBT="-lblastrampoline-5"
else
  LBT="-lblastrampoline"
fi

if [[ "${target}" == *linux* ]]; then
    export CFLAGS="-lrt"
fi

LINKER_FLAGS=""
if [[ "${target}" == *aarch64-apple-darwin* ]]; then
    LINKER_FLAGS="-L${libdir}/darwin -lclang_rt.osx"
fi

cmake .. \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_SHARED_LINKER_FLAGS="${LINKER_FLAGS}" \
    -DPASTIX_WITH_MPI=OFF \
    -DPASTIX_WITH_FORTRAN=ON \
    -DBUILD_PYTHON=OFF \
    -DBUILD_LIBS=ON \
    -DBUILD_DOCUMENTATION=OFF \
    -DBLAS_LIBRARIES=$LBT \
    -DLAPACK_LIBRARIES=$LBT \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DPASTIX_INT64=OFF \
    -DPASTIX_ORDERING_SCOTCH=ON \
    -DPASTIX_ORDERING_METIS=ON

make -j${nproc}
make install

rm -r $prefix/share/bash-completion
rm -r $prefix/share/doc
rm -r $prefix/lib/julia
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
platforms = filter(p -> libgfortran_version(p) != v"3", platforms)
platforms = filter(p -> arch(p) != "riscv64", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libpastix", :libpastix),
    LibraryProduct("libpastixf", :libpastixf),
    LibraryProduct("libspm", :libspm),
    LibraryProduct("libspmf", :libspmf)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="METIS_jll", uuid="d00139f3-1899-568f-a2f0-47f597d42d70")),
    Dependency(PackageSpec(name="SCOTCH_jll", uuid="a8d0f55d-b80e-548d-aff6-1a04c175f0f9"); compat="~7.0.6"),
    Dependency(PackageSpec(name="Hwloc_jll", uuid="e33a78d0-f292-5ffc-b300-72abe9b543c8")),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.9", preferred_llvm_version=v"13.0.1")
