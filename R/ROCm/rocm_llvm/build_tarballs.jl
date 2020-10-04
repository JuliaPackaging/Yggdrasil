# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "rocm_llvm"
version = v"3.8.0"

# Collection of sources required to build
sources = [
    ArchiveSource("https://github.com/RadeonOpenCompute/llvm-project/archive/rocm-$(version).tar.gz",
                  "93a28464a4d0c1c9f4ba55e473e5d1cde4c5c0e6d087ec8a0a3aef1f5f5208e8")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/llvm-project*/

mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DLLVM_ENABLE_PROJECTS="clang;lld;clang-tools-extra;compiler-rt" \
      -DLLVM_ENABLE_ASSERTIONS=ON \
      -DBUILD_SHARED_LIBS=OFF \
      ../llvm
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# The rest of the ROCm stack only seem to support 64bit Linux:
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libclang", :libclang, dont_dlopen=true),
    ExecutableProduct("llvm-config", :llvm_config, "tools"),
    ExecutableProduct("clang", :clang, "tools"),
    ExecutableProduct("opt", :opt, "tools"),
    ExecutableProduct("llc", :llc, "tools"),
    ExecutableProduct("llvm-mca", :llvm_mca, "tools"),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("Ncurses_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               preferred_gcc_version=v"8") 
