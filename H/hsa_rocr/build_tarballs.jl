# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "hsa_rocr"
version = v"4.5.2"

# Collection of sources required to build
sources = [
    ArchiveSource("https://github.com/RadeonOpenCompute/ROCR-Runtime/archive/rocm-$(version).tar.gz",
                  "d99eddedce0a97d9970932b64b0bb4743e47d2740e8db0288dbda7bec3cefa80"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/ROCR-Runtime*/

# Do not install legacy symlinks which only creates confusion with RUNPATHs
atomic_patch -p1 ../patches/no-symlinks.patch

# Fix use of pthread_attr_setaffinity_np
atomic_patch -p1 ../patches/musl-affinity.patch

mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_SKIP_RPATH=ON \
      -DIMAGE_SUPPORT=OFF \
      ../src
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Only supports Linux, seemingly only 64bit
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libhsa-runtime64"], :libhsa_runtime64),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("hsakmt_roct_jll"),
    Dependency("NUMA_jll"),
    Dependency("Zlib_jll"),
    Dependency("Elfutils_jll", compat="0.182"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               julia_compat="1.7",
               preferred_gcc_version=v"8")
