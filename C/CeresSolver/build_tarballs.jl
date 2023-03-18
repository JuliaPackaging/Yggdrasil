using BinaryBuilder

name = "CeresSolver"
version = v"2.1.0"

sources = [
    GitSource("https://github.com/ceres-solver/ceres-solver.git",
              "f68321e7de8929fbcdb95dd42877531e64f72f66")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir cmake_build
cd cmake_build/

if [[ "$target" == *-freebsd* || "$target" == *-apple-* ]]; then
  # Clang doesn't play nicely with OpenMP and
  # compilation fails with glog due to a c++11 error
  CMAKE_FLAGS=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake
               -DMINIGLOG=ON)
else
  CMAKE_FLAGS=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
               -DGLOG_INCLUDE_DIR_HINTS=${prefix}/include)
fi

CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix}
              -DBUILD_SHARED_LIBS=ON
              -DBUILD_EXAMPLES=OFF
              -DBUILD_TESTING=OFF
              -DOPENMP=ON
              -DTBB=OFF
              -DBLAS_LIBRARIES=${libdir}/libopenblas.${dlext}
              -DLAPACK_LIBRARIES=${libdir}/libopenblas.${dlext}
              -DMETIS_LIBRARY=${libdir}/libmetis.${dlext}
              -DSUITESPARSE_INCLUDE_DIR_HINTS=${prefix}/include
              -DAMD_LIBRARY="${libdir}/libamd.${dlext} ${libdir}/libsuitesparseconfig.${dlext}"
              -DCAMD_LIBRARY="${libdir}/libcamd.${dlext} ${libdir}/libsuitesparseconfig.${dlext}"
              -DCCOLAMD_LIBRARY="${libdir}/libccolamd.${dlext} ${libdir}/libsuitesparseconfig.${dlext}"
              -DCHOLMOD_LIBRARY="${libdir}/libcholmod.${dlext} ${libdir}/libsuitesparseconfig.${dlext}"
              -DCOLAMD_LIBRARY="${libdir}/libcolamd.${dlext} ${libdir}/libsuitepsarseconfig.${dlext}"
              -DSUITESPARSEQR_LIBRARY="${libdir}/libspqr.${dlext} ${libdir}/libsuitesparseconfig.${dlext}"
              -DSUITESPARSE_CONFIG_LIBRARY="${libdir}/libsuitesparseconfig.${dlext}"
              )

cmake ${CMAKE_FLAGS[@]} ..

make -j${nproc}
make install

cd ..
"""

platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libceres", :libceres),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Eigen_jll"),
    Dependency("glog_jll"),
    Dependency("METIS_jll"),
    Dependency("OpenBLAS32_jll"),
    Dependency("SuiteSparse_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
