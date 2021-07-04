# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SLATEC"
version = v"4.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sabjohnso/slatec.git",
              "417db9e31c49eba4aee5ab9bb719093f6886bcee"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/slatec/src

# Manually set LAPACK and BLAS libraries
echo "list( REMOVE_ITEM SLATEC_SOURCE_FILES \${BLAS_SOURCE_FILES} )" >> CMakeLists.txt
echo "list( APPEND SLATEC_SOURCE_FILES \${RETAINED_BLAS_SOURCE_FILES} )" >> CMakeLists.txt
echo "list( REMOVE_ITEM SLATEC_SOURCE_FILES \${EXCLUDE_FROM_SHARED} )" >> CMakeLists.txt
echo "include(\$ENV{prefix}/lib/cmake/lapack-3.9.0/lapack-config.cmake)" >> CMakeLists.txt
echo "include(\$ENV{prefix}/lib/cmake/openblas/OpenBLASConfig.cmake)" >> CMakeLists.txt
echo "add_library( slatec_shared SHARED \${SLATEC_SOURCE_FILES} )" >> CMakeLists.txt
echo "target_link_libraries( slatec_shared \${LAPACK_LIBRARIES} \${OpenBLAS_LIBRARIES})" >> CMakeLists.txt
echo "set_target_properties( slatec_shared PROPERTIES OUTPUT_NAME slatec )" >> CMakeLists.txt
echo "install( TARGETS slatec_shared LIBRARY DESTINATION lib )" >> CMakeLists.txt

if [[ "${target}" == aarch64-apple-* ]]; then
    # Fix issue due to GCC 10+.
    #     [  2%] Building Fortran object src/CMakeFiles/slatec_shared.dir/dwnlsm.f.o
    #     cd /workspace/srcdir/slatec/build/src && /opt/bin/aarch64-apple-darwin20-libgfortran5-cxx11/aarch64-apple-darwin20-gfortran --sysroot=/opt/aarch64-apple-darwin20/aarch64-apple-darwin20/sys-root -Dslatec_shared_EXPORTS  -O3 -DNDEBUG -O3 -fPIC   -c /workspace/srcdir/slatec/src/dwnlsm.f -o CMakeFiles/slatec_shared.dir/dwnlsm.f.o
    #     /workspace/srcdir/slatec/src/dwnlsm.f:440:28:
    #
    #       119 |       CALL DCOPY (N, 1.D0, 0, D, 1)
    #           |                     2
    #     ......
    #       440 |          CALL DCOPY (NSOLN, Z, 1, X, 1)
    #           |                            1
    #     Error: Rank mismatch between actual argument at (1) and actual argument at (2) (scalar and rank-1)
    #     /workspace/srcdir/slatec/src/dwnlsm.f:608:25:
    #
    #       119 |       CALL DCOPY (N, 1.D0, 0, D, 1)
    #           |                     2
    #     ......
    #       608 |       CALL DCOPY (NSOLN, Z, 1, X, 1)
    #           |                         1
    #     Error: Rank mismatch between actual argument at (1) and actual argument at (2) (scalar and rank-1)
    export FFLAGS="-fallow-argument-mismatch"
fi

mkdir ../build
cd ../build/
# Above on the fly added CMake code buils shared library with OpenBLAS
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_OPTIMIZED_BLAS=0 \
    -DBUILD_SHARED_LIBRARY=0 \
    ..
make -j${nproc}
make install

install_license ../../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libslatec", :libslatec)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="LAPACK_jll", uuid="51474c39-65e3-53ba-86ba-03b1b862ec14")),
    Dependency(PackageSpec(name="OpenBLAS_jll", uuid="4536629a-c528-5b80-bd46-f80d51c5b363")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
# For the time being need LLVM 11 because of <https://github.com/JuliaPackaging/BinaryBuilderBase.jl/issues/158>.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_llvm_version=v"11")
