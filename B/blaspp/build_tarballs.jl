using BinaryBuilder

name = "blaspp"
version = v"2021.04.01"

# Collection of sources required to build PETSc. Avoid using the git repository, it will
# require building SOWING which fails in all non-linux platforms.
sources = [
    GitSource("https://bitbucket.org/icl/blaspp.git", "314bafceead689a35aab826e03aa76bf329cfb0e")
]

# Bash recipe for building across all platforms

# Needs to add -Dcapi eventually once it's added to the cmake build system. Note yet available under CMAKAE toolchain.
script = raw"""
cd blaspp
mkdir build && cd build
cmake \
  -DCMAKE_INSTALL_PREFIX=${prefix} \
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
  -DCMAKE_BUILD_TYPE="Release" \
  -DBLAS_LIBRARIES="-lblastrampoline" \
  -Drun_result="0" \
  -Drun_result__TRYRUN_OUTPUT="ok" \
  -Dgpu_backend=none \
  -Duse_cmake_find_blas=true \
  -DCMAKE_CXX_FLAGS="-I${includedir}/LP64/${target}" \
  -Dbuild_tests=no \
  ..
make -j${nproc}
make install
"""

# We attempt to build for all defined platforms
platforms = expand_cxxstring_abis(supported_platforms(;experimental=true))
# platforms = filter(p -> !(Sys.iswindows(p) ||Sys.isapple(p)), platforms)
# platforms = filter(!Sys.isfreebsd, platforms)
# platforms = expand_gfortran_versions(platforms)
# platforms = filter(p -> libgfortran_version(p) ≠ v"3", platforms)
products = [
    LibraryProduct("libblaspp", :libblaspp)
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("libblastrampoline_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
