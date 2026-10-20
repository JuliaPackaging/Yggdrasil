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

# (2) ASL appends x86-only -m32/-m64 to anything UNIX that isn't ARM, so aarch64,
#     riscv64, s390x, ... all get a flag their compiler rejects. Make the flag
#     guard an x86 allowlist (keeping the AIX -maix64 case) instead of an ARM blocklist
sed -i 's@if(UNIX AND NOT CPUARCH MATCHES "arm")@if(UNIX AND (CPUARCH MATCHES "^(i386|x86_64)$" OR (CPUARCH MATCHES "ppc64" AND CMAKE_SYSTEM_NAME STREQUAL "AIX")))@' support/cmake/setArchitecture.cmake

# (3) file_kind() uses the raw S_IFDIR/S_IFREG constants, which FreeBSD gates behind
#     __XSI_VISIBLE; use the always-defined POSIX S_ISDIR/S_ISREG macros instead
#     (also fixes a latent bug: the raw test doesn't mask S_IFMT)
sed -i 's/sb\.st_mode & S_IFDIR/S_ISDIR(sb.st_mode)/; s/sb\.st_mode & S_IFREG/S_ISREG(sb.st_mode)/' \
    src/solvers/funcadd1.c src/solvers2/funcadd1.c

# (4) install() couples asl + asl2; we only ship libasl2, so drop asl from the
#     install/export rule. This lets us build asl2 alone and reuse CMake's own
#     per-platform install logic (RUNTIME/LIBRARY/ARCHIVE destinations)
sed -i 's/install(TARGETS asl asl2 /install(TARGETS asl2 /' CMakeLists.txt

cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON
cmake --build build --parallel
cmake --install build
rm -rf ${prefix}/include/asl
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
