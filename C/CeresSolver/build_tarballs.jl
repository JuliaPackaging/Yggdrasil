using BinaryBuilder, Pkg

name = "CeresSolver"
version = v"2.2.0"

sources = [
    GitSource("https://github.com/ceres-solver/ceres-solver.git",
              "125c06882960d87f25f2e0ccb217a949528b017c")
]

# Bash recipe for building across all platforms
script = raw"""
if [[ "${target}" == *-mingw* ]]; then
    BLAS_NAME=libblastrampoline-5
else
    BLAS_NAME=libblastrampoline
fi

CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix}
              -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
              -DCMAKE_BUILD_TYPE=Release
              -DBUILD_SHARED_LIBS=ON
              -DBUILD_EXAMPLES=OFF
              -DBUILD_TESTING=OFF
              -DMETIS_LIBRARY=${libdir}/libmetis.${dlext}
              -DBLAS_LIBRARIES=${libdir}/${BLAS_NAME}.${dlext} 
              -DLAPACK_LIBRARIES=${libdir}/${BLAS_NAME}.${dlext} 
              )

apk del cmake

cd $WORKSPACE/srcdir/ceres-solver/
mkdir build && cd build
cmake -S .. -B . "${CMAKE_FLAGS[@]}"
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
    BuildDependency("Eigen_jll"),
    Dependency("glog_jll"),
    Dependency("METIS_jll"),
    Dependency("libblastrampoline_jll"; compat="5.8.0"),
    Dependency("SuiteSparse_jll"; compat="~7.2.1"),
    HostBuildDependency(PackageSpec(; name="CMake_jll")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="1.10")
