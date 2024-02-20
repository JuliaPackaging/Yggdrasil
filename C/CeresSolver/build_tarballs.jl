using BinaryBuilder

name = "CeresSolver"
version = v"2.1.0"

sources = [
    GitSource("https://github.com/ceres-solver/ceres-solver.git",
              "f68321e7de8929fbcdb95dd42877531e64f72f66")
]

# Bash recipe for building across all platforms
script = raw"""
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix}
              -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
              -DCMAKE_BUILD_TYPE=Release
              -DBUILD_SHARED_LIBS=ON
              -DBUILD_EXAMPLES=OFF
              -DBUILD_TESTING=OFF
              -DBLAS_LIBRARIES=${libdir}/libopenblas.${dlext}
              -DLAPACK_LIBRARIES=${libdir}/libopenblas.${dlext}
              -DMETIS_LIBRARY=${libdir}/libmetis.${dlext}
              )

cd $WORKSPACE/srcdir/ceres-solver/
mkdir build && cd build
cmake .. ${CMAKE_FLAGS[@]}
make -j${nproc}
make install
"""

platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libceres", :libceres),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # CeresSolver is removing OpenMP and dependencies for OpenMP are dropped
    # https://github.com/ceres-solver/ceres-solver/issues/886
    # Eigen_jll v0.3.4 throws errors on powerpc64le with older GCC versions
    BuildDependency("Eigen_jll"),
    Dependency("glog_jll"),
    # Metis replaces SuiteSparse on Windows
    Dependency("METIS_jll"),
    Dependency("OpenBLAS32_jll"),
    # Hard code the version now as the latest v7.0.1 does not get recognized
    Dependency("SuiteSparse_jll", v"5.10.1")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="1.6")
