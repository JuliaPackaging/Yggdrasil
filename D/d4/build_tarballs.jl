using BinaryBuilder, BinaryBuilderBase

name = "d4"
version = v"2.0.0"

# Using official upstream repository with fixed latest commit hash
sources = [
    GitSource("https://github.com/crillab/d4v2.git", "15eff31962466804a48374826b9e5a746fc2766e"),
    DirectorySource("./patches")
]

script = raw"""
cd ${WORKSPACE}/srcdir/d4v2*

# 1. Apply logic, build system, and platform fixes via patch file
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/d4-all-fixes.patch

# 2. Inject broad compatibility headers (cstdint, stdexcept)
find . -type f \( -name "*.cpp" -o -name "*.hpp" -o -name "*.cc" -o -name "*.h" \) -exec sed -i '1i #include <cstdint>\n#include <stdexcept>' {} +
# Fix u_int types globally (fallback for non-glibc systems)
find . -type f \( -name "*.cpp" -o -name "*.hpp" -o -name "*.cc" -o -name "*.h" \) -exec sed -i 's/u_int\([0-9]\+\)_t/uint\1_t/g' {} +

# 3. Build using CMake
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install

# 4. License
install_license LICENSE
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("d4", :d4),
    LibraryProduct("libd4", :libd4)
]

dependencies = [
    Dependency("GMP_jll"; compat="6.2.1"),
    Dependency("boost_jll"; compat="1.79.0"),
    Dependency("oneTBB_jll"),
    Dependency("Zlib_jll"),
    # CompilerSupportLibraries is required on Windows to bundle libstdc++ and libgcc runtime DLLs.
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(Sys.iswindows, platforms))
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"11")
