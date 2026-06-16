# solvers2.tgz is the multithreaded variant of the AMPL Solver Library, in
# which evaluations operate on a given EvalWorkspace, so that distinct
# workspaces may evaluate concurrently from different threads.

using BinaryBuilder

name = "ASL2"
version = v"2025.11.21"

# Sources required to build ASL2.
sources = [
    GitSource("https://github.com/ampl/asl",
              "3d477ba78a3392b8b7b05a2fd843ae7f9df70252")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/asl

# (1) x86 cross branch writes arith.h to the wrong dir
sed -i 's|file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/arith.h|file(WRITE ${GENERATED_INCLUDE_DIR}/arith.h|' CMakeLists.txt

# (2) ASL's arch detector has no __aarch64__ branch, so 64-bit ARM is misdetected
#     and gets the x86-only -m64. Add an arm64 branch (emit "arm64" so the existing
#     `MATCHES "arm"` guard catches it)
sed -i 's@#if defined(__arm__) || defined(__TARGET_ARCH_ARM)@#if defined(__aarch64__) || defined(_M_ARM64)\n    #error cmake_ARCH arm64\n#elif defined(__arm__) || defined(__TARGET_ARCH_ARM)@' support/cmake/setArchitecture.cmake

# (3) -maix64 is AIX-only; restrict it to AIX so Linux ppc64le doesn't get it
sed -i 's@if(CPUARCH MATCHES "ppc64") # on AIX@if(CPUARCH MATCHES "ppc64" AND CMAKE_SYSTEM_NAME STREQUAL "AIX") # on AIX@' support/cmake/setArchitecture.cmake

cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON
cmake --build build --parallel
cmake --install build

install_license LICENSE
"""

platforms = supported_platforms()

# The products that we will ensure are always built.
# The library is named libasl2 so that ASL_jll and ASL2_jll can coexist in
# the same process; the asl_* entry points keep their names, since each JLL
# resolves symbols within its own library handle.
products = [
    LibraryProduct("libasl2", :libasl2)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat = "1.6")
