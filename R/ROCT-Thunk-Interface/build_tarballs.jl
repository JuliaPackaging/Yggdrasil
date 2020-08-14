# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "ROCT-Thunk-Interface"
version = v"3.5.0"

# Collection of sources required to build ROCT-Thunk-Interface
sources = [
    GitSource("https://github.com/RadeonOpenCompute/ROCT-Thunk-Interface.git",
              "d4b224fafc82decdf3210b68ae763a1f345bf3a1"),
#    ArchiveSource("https://github.com/RadeonOpenCompute/ROCT-Thunk-Interface/archive/rocm-$(version).tar.gz",
#                  "d9f458c16cb62c3c611328fd2f2ba3615da81e45f3b526e45ff43ab4a67ee4aa")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/ROCT-Thunk-Interface*/

mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_C_FLAGS="-Dstatic_assert=_Static_assert" \
      ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# ROCT-Thunk-Interface only supports Linux
platforms = [
    Linux(:x86_64, libc=:glibc),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libhsakmt"], :libhsakmt),
]

# Dependencies that must be installed before this package can be built
# This is really a build dependency
dependencies = [
    Dependency("NUMA_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               preferred_gcc_version=v"8") 
