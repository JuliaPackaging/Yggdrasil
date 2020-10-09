# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "hsakmt_roct"
version = v"3.8.0"

# Collection of sources required to build ROCT-Thunk-Interface
sources = [
    ArchiveSource("https://github.com/RadeonOpenCompute/ROCT-Thunk-Interface/archive/rocm-$(version).tar.gz",
                  "cd5440f31f592737b5d05448704bd01f91f73cfcab8a7829922e81332575cfe8"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/ROCT-Thunk-Interface*/

# fix for musl (but works on glibc too)
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/0001-Build-correctly-on-musl.patch"

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
# ROCT-Thunk-Interface only supports Linux, seemingly only 64bit
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libhsakmt"], :libhsakmt),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("NUMA_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               preferred_gcc_version=v"8") 
