using BinaryBuilder

name = "blaspp"
version = v"2021.04.02" # +1 patch version for switching back to openblas

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
  -Drun_result="0" \
  -Drun_result__TRYRUN_OUTPUT="ok" \
  -Dgpu_backend=none \
  -Dbuild_tests=no \
  ..
make -j${nproc}
make install
"""

# We attempt to build for all defined platforms
platforms = expand_cxxstring_abis(supported_platforms(;experimental=true))
products = [
    LibraryProduct("libblaspp", :libblaspp)
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS32_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
