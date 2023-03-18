using BinaryBuilder, Pkg

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
              -DCMAKE_CXX_STANDARD=17
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

cd ..
"""

platforms = expand_cxxstring_abis(supported_platforms())
# Build for all platforms with cxx03 ABI fails
filter!(p->cxxstring_abi(p) !== "cxx03", platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libceres", :libceres),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll",
        uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
        platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll",
        uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
        platforms=filter(Sys.isbsd, platforms)),
    BuildDependency("Eigen_jll"),
    Dependency("glog_jll"),
    Dependency("METIS_jll"),
    Dependency("OpenBLAS32_jll"),
    Dependency("SuiteSparse_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
