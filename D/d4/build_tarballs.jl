using BinaryBuilder

name = "d4"
version = v"2.0.0"

# Collection of sources
sources = [
    GitSource("https://github.com/crillab/d4v2.git", "15eff31962466804a48374826b9e5a746fc2766e"),
    DirectorySource(joinpath(@__DIR__, "patches"))
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/d4v2

# 1. Apply patches (using -p0 for simplified paths)
atomic_patch ${WORKSPACE}/srcdir/d4v2 ${WORKSPACE}/srcdir/01-glucose-fpu-fix.patch -p0
atomic_patch ${WORKSPACE}/srcdir/d4v2 ${WORKSPACE}/srcdir/02-disable-patoh.patch -p0
atomic_patch ${WORKSPACE}/srcdir/d4v2 ${WORKSPACE}/srcdir/03-portability-fixes.patch -p0

# 2. Use our clean CMakeLists.txt (replacing the upstream one which is not cross-friendly)
cp ${WORKSPACE}/srcdir/CMakeLists.txt .

# 3. Build using CMake (both shared library and executable)
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
         -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
         -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("d4", :d4),
    LibraryProduct("libd4", :libd4)
]

dependencies = [
    Dependency("GMP_jll"; compat="6.2.1"),
    Dependency("boost_jll"; compat="1.79.0"),
    Dependency("oneTBB_jll"),
    Dependency("Zlib_jll"),
    # CompilerSupportLibraries_jll is required for GCC runtime on Windows
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(Sys.iswindows, platforms)),
]

# preferred_gcc_version=v"11" is REQUIRED for Boost 1.87 compatibility.
# We use julia_compat="1.10" to resolve the conflict with GCC 11.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
               julia_compat="1.10", preferred_gcc_version=v"11")
