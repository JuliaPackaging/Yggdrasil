using BinaryBuilder, Pkg

name = "singularity_eos"
version = v"1.10.0"

sources = [
    GitSource("https://github.com/lanl/singularity-eos", "82df6cff9ca8b16f8468f20b9d1eaeff60ac53c7"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/singularity-eos
cmakeflags=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DSINGULARITY_BUILD_FORTRAN_BACKEND=ON
    # -DSINGULARITY_BUILD_STELLARCOLLAPSE2SPINER=ON
    -DSINGULARITY_USE_HELMHOLTZ=ON
    # -DSINGULARITY_USE_SPINER=ON
    # -DSINGULARITY_USE_SPINER_WITH_HDF5=ON
    -DSINGULARITY_USE_SPINER=OFF   # we can enable this once we have `spiner_jll`
    # -DSINGULARITY_USE_STELLAR_COLLAPSE=ON
    -DBUILD_SHARED_LIBS=ON
)
cmake -Bbuild "${cmakeflags[@]}"
cmake --build build --parallel ${nprocs}
cmake --install build
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

products = [
    LibraryProduct("libsingularity-eos", :libsingularity_eos),
    # ExecutableProduct("stellarcollapse2spiner", :stellarcollapse2spiner),
]

dependencies = [
    BuildDependency("Eigen_jll"),
    BuildDependency("MPark_Variant_jll"),
    BuildDependency("ports_of_call_jll"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    # Dependency("HDF5_jll"; compat="2.0.0"),
]

# We need at least GCC 10 for C++17
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"11")
