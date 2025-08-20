# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LLVMLibcxx"
version = v"18.1.7"

sources = [
    GitSource("https://github.com/llvm/llvm-project.git",
              "768118d1ad38bf13c545828f67bd6b474d61fc55"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/llvm-project/runtimes

export CXXFLAGS=-pthread
cmake -B build \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_INSTALL_PREFIX=${prefix}/libcxx \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_RUNTIMES='libcxx;libcxxabi' \
    -DLIBCXX_INCLUDE_BENCHMARKS=OFF \
    -DLIBCXX_HAS_ATOMIC_LIB=NO \
    -DLIBCXX_USE_COMPILER_RT=ON \
    -DLIBCXX_ENABLE_SHARED=ON \
    -DLIBCXX_ENABLE_STATIC=ON \
    -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON \
    -DLIBCXX_INSTALL_MODULES=ON \
    -DLIBCXXABI_USE_COMPILER_RT=ON \
    -DLIBCXXABI_USE_LLVM_UNWINDER=OFF

cmake --build build --parallel ${nproc}
cmake --install build

install_license ../LICENSE.TXT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> libc(p) == "glibc", platforms)
filter!(p -> arch(p) != "riscv64", platforms)
filter!(p -> !(arch(p) in ("armv7l", "armv6l")), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libc++", :libcxx, ["libcxx/lib"]),
    LibraryProduct("libc++abi", :libcxxabi, ["libcxx/lib"]),
    FileProduct("libcxx/include/c++/v1", :includecxxv1_dir),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("XML2_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"13")
