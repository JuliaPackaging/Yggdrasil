using BinaryBuilder

name = "lapackpp"
version = v"2021.04.00"

# Collection of sources required to build PETSc. Avoid using the git repository, it will
# require building SOWING which fails in all non-linux platforms.
sources = [
    GitSource("https://bitbucket.org/icl/lapackpp.git", "31d969200a9f65390f56ac2ea48888bd10a13397")
]

# Bash recipe for building across all platforms

# Needs to add -Dcapi eventually once it's added to the cmake build system. Note yet available under CMAKAE toolchain.
script = raw"""
cd lapackpp
mkdir build && cd build
cmake \
  -DCMAKE_INSTALL_PREFIX=${prefix} \
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
  -DCMAKE_BUILD_TYPE="Release" \
  -Drun_result="0" \
  -Drun_result__TRYRUN_OUTPUT="ok" \
  -Dbuild_tests=no \
  -Duse_cmake_find_lapack=yes \
  ..
make -j${nproc}
make install
"""

# We attempt to build for all defined platforms
platforms = expand_cxxstring_abis(supported_platforms())
products = [
    LibraryProduct("liblapackpp", :liblapackpp)
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS32_jll"),
    Dependency("blaspp_jll"; compat="2021.04.02")
]
# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
